# Telegram Bot Architecture

This document describes the architecture and patterns used in the Telegram bot implementation.

## 📋 Table of Contents

- [Overview](#overview)
- [Controller Architecture](#controller-architecture)
- [Command System](#command-system)
- [Context Management](#context-management)
- [Session Management](#session-management)
- [Error Handling](#error-handling)
- [Testing Patterns](#testing-patterns)

## Overview

The Telegram bot is built using the `telegram-bot-rb` gem with a custom command-based architecture that separates business logic into command classes.

### Key Components

- **`Telegram::WebhookController`** - Main entry point for all Telegram updates
- **Command Classes** - Business logic for specific commands (`/client`, `/projects`, etc.)
- **`Telegram::CommandRegistry`** - Registry system for available commands
- **`Telegram::Callbacks`** - Callback query handling
- **`Telegram::ErrorHandling`** - Centralized error handling with Bugsnag integration

## Controller Architecture

### Core Structure

```ruby
module Telegram
  class WebhookController < Telegram::Bot::UpdatesController
    include Telegram::Bot::UpdatesController::Session
    include Telegram::Bot::UpdatesController::MessageContext
    include Telegram::Bot::UpdatesController::CallbackQueryContext
    include Telegram::Callbacks
    include Telegram::ErrorHandling
    include Telegram::SessionHelpers

    use_session!

    # Command methods are dynamically defined here
    Telegram::CommandRegistry.available_commands.each do |command|
      define_method "#{command}!" do |*args|
        command_class = Telegram::CommandRegistry.get(command)
        command_class.new(self).call(*args)
      end
    end
  end
end
```

### Update Types

The controller handles different update types:

- **`message`** - Regular text messages and time tracking entries
- **`callback_query`** - Inline button clicks
- **Commands** - Messages starting with `/` (e.g., `/start`, `/help`)

## Command System

### Command Registration

Commands are registered in `config/initializers/command_registry.rb`:

```ruby
Rails.application.config.after_initialize do
  Telegram::CommandRegistry.register(
    %w[day summary report projects attach start help version
       users merge add new adduser hours edit rename
       rate client reset]
  )
end
```

### Command Structure

Each command inherits from `BaseCommand`:

```ruby
class ClientCommand < BaseCommand
  # Declare context methods this command provides
  provides_context_methods :add_client_name, :add_client_key, :edit_client_name

  def call(subcommand = nil, *args)
    # Main command logic
  end

  # Context methods for multi-step interactions
  def add_client_name(message = nil, *)
    # Context handling logic
  end
end
```

### Available Commands

- **`day`** - Daily time tracking summary
- **`summary`** - Period summaries
- **`report`** - Detailed reports
- **`projects`** - Project management
- **`attach`** - Attach time to projects
- **`start`** - Start workflow
- **`help`** - Help information
- **`version`** - Bot version
- **`users`** - User management
- **`merge`** - Merge operations
- **`add`** - Add time entries
- **`new`** - Create new items
- **`adduser`** - Add users to projects
- **`hours`** - Hours tracking
- **`edit`** - Edit time entries
- **`rename`** - Rename projects
- **`rate`** - Rate management
- **`client`** - Client management
- **`reset`** - Reset operations

## Context Management

Context management enables multi-step conversations where the bot remembers what the user was doing between messages.

### 🎯 How Context Works in telegram-bot-rb

The telegram-bot-rb gem provides two main context mechanisms:

#### 1. MessageContext (for regular messages)

**Pattern**: `save_context :method_name` → calls `method_name` on next message

```ruby
def some_command!(*)
  save_context :waiting_for_input
  respond_with :message, text: 'Please enter your input:'
end

def waiting_for_input(message, *)
  # This method will be called on the next message
  process_input(message)
end
```

**Key Rules**:
- Context name = method name (no additional suffixes)
- Method must be defined in the controller
- Works with regular text messages

#### 2. CallbackQueryContext (for inline buttons)

**Pattern**: `callback_data: "prefix:data"` → calls `prefix_callback_query(data)`

```ruby
# When creating inline keyboard:
reply_markup: {
  inline_keyboard: [
    [{ text: 'Set Value', callback_data: 'set_value:123' }]
  ]
}

# Handler method:
def set_value_callback_query(value, *)
  # value will be "123"
  process_value(value)
  answer_callback_query('Value saved!')
end
```

**Key Rules**:
- Method name = prefix + `_callback_query`
- Data after `:` is passed as argument
- Works with callback button clicks

### Context Method Delegation

Since context methods need to be available in the controller, we use a delegation system:

```ruby
# In BaseCommand
class << self
  def provides_context_methods(*methods)
    @context_methods ||= []
    @context_methods.concat(methods.map(&:to_sym))
    @context_methods.uniq!
  end

  def context_method_names
    @context_methods || []
  end
end

# In WebhookController - automatic registration
command_class.context_method_names.each do |context_method|
  define_method context_method do |*args|
    command_instance = command_class.new(self)
    command_instance.send(context_method, *args)
  end
end
```

### Real-world Example: Client Management

```ruby
class ClientCommand < BaseCommand
  provides_context_methods :add_client_name, :add_client_key, :edit_client_name

  def call(subcommand = nil, *args)
    case subcommand
    when 'add'
      handle_add_client
    # ...
    end
  end

  def handle_add_client
    save_context :add_client_name
    respond_with :message, text: 'Enter client name:'
  end

  # Context method - will be called on next message
  def add_client_name(message = nil, *)
    name = message&.strip
    if name.blank?
      respond_with :message, text: 'Name cannot be empty'
      save_context :add_client_name  # Stay in same context
      return
    end

    session[:client_name] = name
    save_context :add_client_key  # Move to next context
    respond_with :message, text: 'Enter client key:'
  end

  # Another context method
  def add_client_key(message = nil, *)
    key = message&.strip&.downcase
    name = session[:client_name]

    # Create client...
    client = current_user.clients.create!(key: key, name: name)
    session.delete(:client_name)

    respond_with :message, text: "Client #{client.name} created!"
  end
end
```

## Session Management

### Session Storage

The bot uses Rails session with per-user-per-chat isolation:

```ruby
def session_key
  "#{bot.username}:#{chat['id']}:#{from['id']}" if chat && from
end
```

### Session Usage

```ruby
# Store data
session[:client_name] = name

# Retrieve data
name = session[:client_name]

# Clean up
session.delete(:client_name)
```

### TelegramSession

For complex workflows, the bot uses `TelegramSession` model:

```ruby
# Create specialized session
self.telegram_session = TelegramSession.add_time(project_id: project.id)

# Access session data
data = telegram_session_data
project_id = data['project_id']
```

## Error Handling

### Error Handling Flow

1. **All errors are caught** by `Telegram::ErrorHandling` module
2. **Bugsnag notification** is sent for all errors
3. **User-friendly message** is sent to user
4. **Error is logged** for debugging

### Error Handling Pattern

```ruby
module Telegram::ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :handle_error
  end

  private

  def handle_error(exception)
    notify_bugsnag(exception)
    respond_with :message, text: 'Something went wrong. Please try again.'
  end

  def notify_bugsnag(exception)
    Bugsnag.notify(exception) do |notification|
      notification.add_metadata(:telegram, {
        user_id: from['id'],
        chat_id: chat['id'],
        message: payload['text']
      })
    end
  end
end
```

## Testing Patterns

### Controller Tests

```ruby
RSpec.describe Telegram::WebhookController, type: :telegram_bot_controller do
  describe '#client!' do
    it 'shows clients list' do
      dispatch_command :client
      expect(response).to send_telegram_message(bot, /Clients/)
    end
  end

  describe '#add_client_name (context method)' do
    it 'processes client name input' do
      session[:context] = 'add_client_name'
      dispatch_message 'Test Client'
      expect(response).to send_telegram_message(bot, /Enter client key/)
    end
  end
end
```

### Command Tests

```ruby
RSpec.describe ClientCommand do
  let(:controller) { double('controller') }
  let(:command) { ClientCommand.new(controller) }

  describe '#call' do
    it 'shows clients list when no subcommand' do
      expect(controller).to receive(:respond_with).with(:message, text: /Clients/)
      command.call
    end
  end
end
```

## Best Practices

### ✅ Do's

1. **Always declare context methods** with `provides_context_methods`
2. **Use session for temporary data** between context steps
3. **Handle errors gracefully** with proper Bugsnag notifications
4. **Test context flows** thoroughly
5. **Clean up session data** when workflows complete
6. **Use descriptive context method names**

### ❌ Don'ts

1. **Don't forget to register** new commands in `command_registry.rb`
2. **Don't use context names** that conflict with existing controller methods
3. **Don't leave session data** hanging after workflows complete
4. **Don't assume context methods exist** - always declare them
5. **Don't mix MessageContext** and CallbackQueryContext patterns

## Debugging Tips

### Common Issues

1. **"Action not found" errors** - Check if context methods are properly declared
2. **Session data loss** - Verify session key is working correctly
3. **Callback not working** - Ensure callback data format matches method name pattern

### Debug Commands

```ruby
# Check available commands
Telegram::CommandRegistry.available_commands

# Check context methods for a command
ClientCommand.context_method_names

# Check if method exists in controller
Telegram::WebhookController.instance_methods.include?(:add_client_name)

# Inspect session data
session.to_h
```

## Architecture Decisions

### Why Command Classes?

- **Separation of concerns** - Business logic separated from HTTP handling
- **Testability** - Commands can be unit tested independently
- **Reusability** - Commands can be called from different contexts
- **Maintainability** - Easier to organize and find command logic

### Why Context Method Delegation?

- **Clean architecture** - Commands own their context methods
- **Automatic registration** - No manual method definition needed
- **Type safety** - Methods are checked at registration time
- **Flexibility** - Easy to add/remove context methods

---

*This document should be updated when new patterns are introduced or existing patterns are modified.*