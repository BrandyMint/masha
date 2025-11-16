# Руководство по разработке

## 📚 Основная документация

/file:telegram-bot-architecture.md
/file:telegram-error-handling.md
/file:telegram-session-management.md
/file:telegram-response-methods.md
/file:gems/telegram-bot.md

## Важные инструкции

## 🏗️ Telegram Bot Architecture

**Контекстные методы**: telegram-bot-rb использует два типа контекстов:
- **MessageContext**: `save_context :method_name` → вызывает `method_name` при следующем сообщении
- **CallbackQueryContext**: `callback_data: "prefix:data"` → вызывает `prefix_callback_query(data)`

**Делегирование контекстов**: Команды декларируют контекстные методы через `provides_context_methods` в `BaseCommand`, которые автоматически регистрируются в `WebhookController`.

**Пример**:
```ruby
class ClientCommand < BaseCommand
  provides_context_methods :add_client_name, :add_client_key

  def add_client_name(message = nil, *)
    # обработка контекста
    save_context :add_client_key  # переход к следующему шагу
  end
end
```
### Обработка ошибок в Telegram

🚨 **КРИТИЧЕСКИ ВАЖНО**: Все обработчики ошибок в Telegram контроллерах ОБЯЗАТЕЛЬНО должны уведомлять Bugsnag.

### Управление сессиями в Telegram

📚 **ВАЖНО**: Понимание разницы между `session` и `TelegramSession` для правильной разработки.

Подробности: [telegram-session-management.md](./telegram-session-management.md)

@docs/development/telegram-session-management.md

### Архитектура Telegram бота

🏗️ **ОСНОВА**: Понимание архитектуры бота, механизма контекстов и системы команд.

Подробности: [telegram-bot-architecture.md](./telegram-bot-architecture.md)

@docs/development/telegram-bot-architecture.md

## Чек-лист при Code Review

- [ ] Все `rescue` блоки имеют `notify_bugsnag(e)`
- [ ] Модуль `Telegram::ErrorHandling` подключен
- [ ] Есть полезные метаданные для отладки
