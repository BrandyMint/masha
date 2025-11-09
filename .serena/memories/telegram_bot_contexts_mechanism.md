# Telegram Bot Contexts Mechanism

## Overview
This document describes how contexts work in telegram-bot-rb gem and our implementation patterns.

## Context Types

### 1. MessageContext
- **Usage**: `save_context :method_name`
- **Behavior**: Calls `method_name` on next message
- **Pattern**: Context name = method name (no suffixes)
- **Use case**: Multi-step text conversations

### 2. CallbackQueryContext  
- **Usage**: `callback_data: "prefix:data"`
- **Behavior**: Calls `prefix_callback_query(data)`
- **Pattern**: Method name = prefix + "_callback_query"
- **Use case**: Inline button interactions

## Implementation in Our Project

### Command Context Declaration
```ruby
class SomeCommand < BaseCommand
  provides_context_methods :method1, :method2
  
  def method1(message, *)
    # Context handling
    save_context :method2  # Move to next step
  end
  
  def method2(message, *)
    # Final step
  end
end
```

### Controller Registration
WebhookController automatically registers context methods from commands:
```ruby
command_class.context_method_names.each do |context_method|
  define_method context_method do |*args|
    command_instance = command_class.new(self)
    command_instance.send(context_method, *args)
  end
end
```

## Key Points

1. Context methods must be declared with `provides_context_methods`
2. Context methods are automatically available in WebhookController
3. Session data persists between context steps
4. Clean up session data when workflows complete
5. Use descriptive context method names

## Debugging

- Check context methods: `CommandClass.context_method_names`
- Verify method exists: `WebhookController.instance_methods.include?(:method_name)`
- Inspect session: `session.to_h`

## Files

- Implementation: `app/commands/base_command.rb`
- Registration: `app/controllers/telegram/webhook_controller.rb`
- Documentation: `docs/development/telegram-bot-architecture.md`

## Recent Fix (2025-11-09)

Fixed issue where context methods were not found in WebhookController:
- Added `provides_context_methods` mechanism to BaseCommand
- Updated ClientCommand with context declarations
- Modified WebhookController to auto-register context methods
- Error: "The context action 'add_client_name' is not found in Telegram::WebhookController"