# Code Conventions and Style Guide

## Ruby/Rails Conventions

### General Style
- **Line Length**: 140 characters (configured in RuboCop)
- **Encoding**: UTF-8 with `# frozen_string_literal: true` at top
- **Indentation**: 2 spaces (no tabs)
- **Naming**: snake_case for files/variables, CamelCase for classes

### Model Conventions
```ruby
# Models with single-line comments in Russian
class User < ApplicationRecord
  # Пользователь системы с OAuth-аутентификацией через GitHub и Telegram
  authenticates_with_sorcery!
  include Authority::UserAbilities
  
  # Associations before validations
  has_many :time_shifts
  belongs_to :telegram_user, optional: true
  
  # Validations
  validates :email, email: true, uniqueness: true
  
  # Scopes
  scope :ordered, -> { order :name }
  
  # Callbacks
  before_save :normalize_email
  
  # Class methods
  def self.find_or_create_by_telegram_data!(data)
    # implementation
  end
  
  # Instance methods
  def available_projects
    projects.ordered
  end
  
  private
  
  def normalize_email
    self.email = nil if email.blank?
  end
end
```

### Controller Conventions
```ruby
class ProjectsController < ApplicationController
  before_action :set_project, only: %i[show edit update destroy]
  before_action :authorize_action! # Authority gem pattern
  
  def index
    @projects = current_user.projects.ordered
  end
  
  private
  
  def set_project
    @project = Project.find(params[:id])
  end
  
  def project_params
    params.require(:project).permit(:name, :description)
  end
end
```

### Service Object Pattern
```ruby
class TelegramTimeTracker
  def initialize(user, message_parts, controller)
    @user = user
    @message_parts = message_parts
    @controller = controller
  end
  
  def call  # or parse_and_add for specific naming
    # main logic
  end
  
  private
  
  def helper_method
    # implementation
  end
end
```

## Telegram Bot Conventions

### Command Structure
```ruby
module Telegram
  module Commands
    class StartCommand < BaseCommand
      def call(*args)
        # Command implementation
      rescue StandardError => e
        notify_bugsnag(e) do |b|
          b.user = current_user
          b.meta_data = { command: :start, args: args }
        end
        respond_with :message, text: t('telegram.errors.general')
      end
    end
  end
end
```

### Error Handling (MANDATORY)
```ruby
# ALL rescue blocks in Telegram controllers MUST notify Bugsnag
rescue StandardError => e
  notify_bugsnag(e) do |b|
    b.user = current_user
    b.meta_data = {
      command: args[0],
      args: args[1..-1],
      session_data: session.keys
    }
  end
  respond_with :message, text: t('telegram.errors.general')
end
```

## Testing Conventions

### RSpec Structure
```ruby
RSpec.describe User, type: :model do
  let(:user) { build(:user) }
  
  describe '#available_projects' do
    it 'returns ordered projects' do
      expect(user.available_projects).to be_ordered
    end
  end
end
```

### Factory Bot
```ruby
# Use Russian attribute names where appropriate
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { 'Тестовый пользователь' }
    
    trait :with_telegram do
      association :telegram_user
    end
  end
end
```

## Frontend Conventions

### JavaScript/jQuery
```javascript
// Use ready handler for Turbolinks compatibility
$(document).on('turbolinks:load', function() {
  // Initialization code
});

// Event delegation for dynamic content
$(document).on('click', '.time-entry', function() {
  // Handler
});
```

### CSS/Sass Structure
```scss
// Follow Bootstrap 5 conventions
.time-shift {
  &__header {
    // Header styles
  }
  
  &__content {
    // Content styles
  }
}
```

## Database Conventions

### Migration Naming
```ruby
class AddTelegramIntegrationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :telegram_user, foreign_key: true, index: true
  end
end
```

### Schema Conventions
- Use PostgreSQL extensions when appropriate
- Add foreign keys and indexes
- Use appropriate data types (jsonb for structured data)
- Add table comments for complex tables

## Documentation

### Russian Language
- **User-facing text**: Russian (default locale)
- **Code comments**: Russian for domain-specific concepts
- **Documentation**: Russian for business specs, mixed for technical docs

### Comments Style
```ruby
# Проверяем формат времени: часы могут быть целыми или дробными
def parse_hours(hours_str)
  # implementation
end
```

## Security Conventions

### Authority Gem Usage
```ruby
# Always authorize actions
before_action :authorize_action!

# Authorizers use whitelist strategy
def self.default(_adjective, user)
  user.is_root?  # Only root users by default
end
```

### Input Validation
```ruby
# Use strong parameters
def user_params
  params.require(:user).permit(:name, :email, :locale)
end

# Validate models
validates :email, email: true, uniqueness: true
```

## Configuration

### Environment Variables
- Use ApplicationConfig for settings
- Keep secrets in environment variables
- Use Russian for configuration comments where appropriate