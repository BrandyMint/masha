# 🏗️ Итоговый план реестра команд

**Дата:** 2025-11-09
**Статус:** К реализации

## Текущая проблема

```ruby
COMMANDS.each do |command|
  define_method "#{command}!" do |*args|
    command_class = "#{command.camelize}Command".constantize  # Может упасть с NameError
    command_class.new(self).call(*args)
  end
end
```

## Решение: Безопасная загрузка классов команд

## 1. Простой реестр команд

```ruby
# app/services/telegram/command_registry.rb
class Telegram::CommandRegistry
  class << self
    attr_reader :commands

    def register(command_list)
      @commands ||= {}

      command_list.each do |command_name|
        class_name = "#{command_name.camelize}Command"

        begin
          command_class = class_name.constantize
          @commands[command_name.to_sym] = command_class
          Rails.logger.info "Command registered: #{command_name} -> #{class_name}"
        rescue NameError => e
          Rails.logger.error "Failed to load command: #{command_name} -> #{class_name}: #{e.message}"
        end
      end
    end

    def get(command_name)
      @commands&.dig(command_name.to_sym)
    end

    def available_commands
      @commands&.keys || []
    end
  end
end
```

## 2. Простая инициализация

```ruby
# config/initializers/command_registry.rb
Telegram::CommandRegistry.register(
  %w[day summary report projects attach start help version
     users merge add new adduser hours edit rename
     rate client reset]
)
```

## 3. Обновленный WebhookController

```ruby
# app/controllers/telegram/webhook_controller.rb
module Telegram
  class WebhookController < Telegram::Bot::UpdatesController
    # ... все остальные части остаются без изменений

    # 🔥 Динамическое определение только для ЗАГРУЖЕННЫХ команд
    Telegram::CommandRegistry.available_commands.each do |command|
      define_method "#{command}!" do |*args|
        command_class = Telegram::CommandRegistry.get(command)
        command_class.new(self).call(*args)
      end
    end

    # ... остальной код без изменений
  end
end
```

## 4. HelpCommand - статический текст как был

`app/commands/help_command.rb` остается без изменений с текущим текстовым блоком справки.

## ✅ Что получаем:

1. **Безопасность**: Не упадёт с `NameError`
2. **Простота**: Минимальные изменения, без лишней сложности
3. **Надёжность**: Логирование ошибок загрузки
4. **Совместимость**: Для пользователей ничего не меняется
5. **Поддерживаемость**: Легко добавлять новые команды через массив в initializer

## Порядок реализации:

1. Создать `app/services/telegram/command_registry.rb`
2. Создать `config/initializers/command_registry.rb`
3. Обновить `app/controllers/telegram/webhook_controller.rb`
4. Проверить что всё работает
5. `HelpCommand` оставить без изменений