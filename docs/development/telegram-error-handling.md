# Правила обработки ошибок в Telegram контроллерах

## Обязательные требования

Все обработчики ошибок в Telegram контроллерах должны уведомлять Bugsnag о любых пойманных исключениях.

## Паттерны использования

### 1. Включаем модуль error handling

```ruby
class MyCommand < BaseCommand
  include Telegram::ErrorHandling

  def call(*args)
    # основной код
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
end
```

### 2. Минимальный обязательный паттерн

Если нужно просто поймать ошибку и отправить в Bugsnag:

```ruby
rescue StandardError => e
  notify_bugsnag(e)
  # обработка для пользователя
end
```

### 3. Паттерн с метаданными

Рекомендуемый паттерн с полезной контекстной информацией:

```ruby
rescue ActiveRecord::RecordInvalid => e
  notify_bugsnag(e) do |b|
    b.user = current_user
    b.meta_data = {
      record: e.record.class.name,
      errors: e.record.errors.full_messages,
      operation: 'create_project'
    }
  end
  respond_with :message, text: "Ошибка: #{e.record.errors.full_messages.join(', ')}"
end
```

## Что нельзя делать

### ❌ Неправильно

```ruby
rescue StandardError => e
  Rails.logger.error e.message
  respond_with :message, text: 'Ошибка'
end
```

### ❌ Нельзя забывать Bugsnag

```ruby
rescue StandardError => e
  respond_with :message, text: t('telegram.errors.general')
  # Забыли notify_bugsnag(e) - НЕДОПУСТИМО!
end
```

## Проверка при Code Review

При ревью кода всегда проверять наличие `notify_bugsnag(e)` во всех `rescue` блоках.

### Чек-лист для ревью:

- [ ] Есть `rescue StandardError => e`
- [ ] Есть вызов `notify_bugsnag(e)`
- [ ] Опционально: есть полезные метаданные (user, meta_data)
- [ ] Есть понятное сообщение для пользователя

## Автоматическая проверка

TODO: Добавить рубокоп правило для проверки наличия `notify_bugsnag` в rescue блоках.

## Примеры правильной обработки

### ✅ Полный пример:

```ruby
module Telegram
  module Commands
    class CreateProjectCommand < BaseCommand
      include Telegram::ErrorHandling

      def call(name = nil)
        project = current_user.projects.create!(name: name)
        respond_with :message, text: "Проект создан: #{project.name}"
      rescue ActiveRecord::RecordInvalid => e
        notify_bugsnag(e) do |b|
          b.user = current_user
          b.meta_data = {
            project_name: name,
            validation_errors: e.record.errors.full_messages
          }
        end
        respond_with :message, text: "Ошибка создания: #{e.record.errors.full_messages.join(', ')}"
      rescue StandardError => e
        notify_bugsnag(e) do |b|
          b.user = current_user
          b.meta_data = {
            project_name: name,
            unexpected_error: true
          }
        end
        respond_with :message, text: t('telegram.errors.general')
      end
    end
  end
end
```

## Почему это важно

1. **Отслеживание проблем в production** - без Bugsnag мы не знаем о реальных ошибках
2. **Контекст для отладки** - метаданные помогают быстрее найти причину
3. **UX** - пользователь получает понятное сообщение, а мы - детальную информацию
4. **Качество кода** - единый стандарт обработки ошибок по всему проекту