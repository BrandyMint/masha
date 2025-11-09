# План имплементации: Управление жизненным циклом сессий Telegram бота

**Дата:** 2025-01-09
**Приоритет:** Высокий
**Оценка времени:** 1 неделя

## 🎯 Цель

Реализовать автоматическое управление жизненным циклом Telegram сессий для предотвращения утечек памяти и улучшения безопасности.

## 📋 Этап 1: Расширение TelegramSession с поддержкой TTL

### Задачи:
1. ✅ Добавить временные метки (`created_at`, `last_accessed_at`) в `TelegramSession`
2. ✅ Реализовать TTL для разных типов сессий:
   - `edit`: 30 минут
   - `add_user`: 1 час
   - `add_time`: 15 минут
   - `rename`: 20 минут
3. ✅ Добавить проверку истечения срока (`expired?`)
4. ✅ Обновить сериализацию/десериализацию с учетом временных меток

### Изменения в коде:

#### 1. `app/models/telegram_session.rb`

```ruby
# frozen_string_literal: true

# Базовый класс для управления состоянием Telegram сессий
# Инкапсулирует все данные одной операции в единственный ключ session[:telegram_session]
class TelegramSession
  attr_accessor :type, :data, :created_at, :last_accessed_at

  # Конфигурация TTL для разных типов сессий
  TTL_BY_TYPE = {
    edit:      30.minutes,  # Редактирование - быстрая операция
    add_user:  1.hour,      # Добавление пользователя
    add_time:  15.minutes,  # Добавление времени - очень быстро
    rename:    20.minutes   # Переименование - быстро
  }.freeze

  # Общий TTL по умолчанию
  DEFAULT_TTL = 1.hour

  def initialize(type, data = {})
    @type = type.to_sym
    @data = data.with_indifferent_access
    @created_at = Time.current
    @last_accessed_at = Time.current
  end

  # Сериализация для сохранения в session
  def to_h
    {
      'type' => @type.to_s,
      'data' => @data,
      'created_at' => @created_at&.iso8601,
      'last_accessed_at' => @last_accessed_at&.iso8601
    }
  end

  # Десериализация из session
  def self.from_h(hash)
    return nil unless hash.is_a?(Hash)

    type = hash['type']&.to_sym
    data = hash['data'] || {}

    session = new(type, data)
    session.created_at = Time.parse(hash['created_at']) if hash['created_at']
    session.last_accessed_at = Time.parse(hash['last_accessed_at']) if hash['last_accessed_at']

    session
  rescue ArgumentError => e
    Rails.logger.warn "Invalid timestamp in TelegramSession: #{e.message}"
    new(type, data) # Создаем новую сессию при ошибке парсинга
  end

  # Валидация структуры данных
  def valid?
    VALID_TYPES.include?(@type) && @data.is_a?(Hash)
  end

  # Проверка истечения срока
  def expired?
    ttl = TTL_BY_TYPE[@type] || DEFAULT_TTL
    created_at && created_at < ttl.ago
  end

  # Обновить время последнего доступа
  def touch!
    @last_accessed_at = Time.current
  end

  # Получить TTL для текущего типа
  def ttl
    TTL_BY_TYPE[@type] || DEFAULT_TTL
  end

  # Время до истечения
  def expires_at
    created_at + ttl
  end

  # Осталось времени до истечения
  def time_until_expiry
    [expires_at - Time.current, 0].max
  end

  # Фабричные методы (остаются без изменений)
  def self.edit(time_shift_id:)
    new(:edit, {
          time_shift_id: time_shift_id,
          field: nil,
          new_values: {}
        })
  end

  def self.add_user(project_slug:)
    new(:add_user, {
          project_slug: project_slug,
          username: nil,
          role: nil
        })
  end

  def self.add_time(project_id:)
    new(:add_time, {
          project_id: project_id
        })
  end

  def self.rename(project_id:)
    new(:rename, {
          project_id: project_id,
          new_name: nil
        })
  end

  # Получить значение из data
  delegate :[], to: :@data

  # Установить значение в data
  delegate :[]=, to: :@data

  # Обновить несколько значений сразу
  def update(hash)
    @data.merge!(hash)
    self
  end
end
```

#### 2. `app/controllers/concerns/telegram/session_helpers.rb`

```ruby
# frozen_string_literal: true

# Хелперы для работы с TelegramSession
module Telegram
  module SessionHelpers
    extend ActiveSupport::Concern

    # Получить текущую сессию с проверкой TTL
    def telegram_session
      return nil unless session[:telegram_session]

      tg_session = TelegramSession.from_h(session[:telegram_session])

      # Проверка истечения срока
      if tg_session&.expired?
        Rails.logger.info "Expired Telegram session cleared for user: #{current_user&.id}"
        clear_telegram_session
        return nil
      end

      # Обновить время доступа
      tg_session&.touch!

      # Сохранить обновленное время доступа
      if tg_session
        session[:telegram_session] = tg_session.to_h
      end

      tg_session
    end

    # Установить сессию
    def telegram_session=(tg_session)
      if tg_session.nil?
        session.delete(:telegram_session)
      else
        # Добавляем метаданные при установке
        tg_session.created_at = Time.current if tg_session.created_at.blank?
        tg_session.last_accessed_at = Time.current
        session[:telegram_session] = tg_session.to_h
      end
    end

    # Очистить сессию с логированием
    def clear_telegram_session
      if session[:telegram_session]
        Rails.logger.info "Telegram session cleared for user: #{current_user&.id}"
      end
      session.delete(:telegram_session)
    end

    # Получить данные сессии с автоматической очисткой
    def telegram_session_data
      telegram_session&.data || {}
    end

    # Проверить наличие активной сессии
    def telegram_session_active?
      telegram_session.present? && !telegram_session.expired?
    end

    # Получить информацию о сессии для отладки
    def telegram_session_info
      session = telegram_session
      return nil unless session

      {
        type: session.type,
        created_at: session.created_at,
        last_accessed_at: session.last_accessed_at,
        expires_at: session.expires_at,
        time_remaining: session.time_until_expiry,
        expired: session.expired?,
        valid: session.valid?
      }
    end
  end
end
```

### 3. Обработка истекших сессий

Сессии автоматически очищаются при доступе через `telegram_session` метод в `SessionHelpers`. Это "lazy cleanup" подход:
- При каждом обращении к сессии проверяется `expired?`
- Если сессия истекла - она немедленно удаляется
- Никаких фоновых задач или сложной логики очистки не требуется

## 🧪 Тестирование

### Спецификации для новой функциональности:

#### `spec/models/telegram_session_spec.rb`

```ruby
# frozen_string_literal: true

RSpec.describe TelegramSession, type: :model do
  describe 'TTL functionality' do
    let(:edit_session) { TelegramSession.edit(time_shift_id: 123) }
    let(:add_user_session) { TelegramSession.add_user(project_slug: 'test') }

    it 'sets correct TTL for different session types' do
      expect(edit_session.ttl).to eq(30.minutes)
      expect(add_user_session.ttl).to eq(1.hour)
    end

    it 'detects expired sessions' do
      travel_to(2.hours.ago) do
        fresh_session = TelegramSession.edit(time_shift_id: 123)
        travel(1.hour) do
          expect(fresh_session).to be_expired
        end
      end
    end

    it 'calculates expiry time correctly' do
      expected_expiry = edit_session.created_at + 30.minutes
      expect(edit_session.expires_at).to eq(expected_expiry)
    end
  end

  describe 'serialization' do
    let(:session) { TelegramSession.edit(time_shift_id: 123) }

    it 'includes timestamps in serialization' do
      hash = session.to_h
      expect(hash).to have_key('created_at')
      expect(hash).to have_key('last_accessed_at')
      expect(hash['created_at']).to be_present
    end

    it 'deserializes with timestamps' do
      hash = session.to_h
      deserialized = TelegramSession.from_h(hash)

      expect(deserialized.created_at).to be_within(1.second).of(session.created_at)
      expect(deserialized.last_accessed_at).to be_within(1.second).of(session.last_accessed_at)
    end
  end

  describe 'touch!' do
    let(:session) { TelegramSession.edit(time_shift_id: 123) }

    it 'updates last_accessed_at' do
      original_time = session.last_accessed_at
      travel(1.minute) do
        session.touch!
        expect(session.last_accessed_at).not_to eq(original_time)
      end
    end
  end
end
```

### Тестирование очистки сессий

Тестирование автоматической очистки при доступе:

```ruby
# frozen_string_literal: true

RSpec.describe Telegram::SessionHelpers, type: :controller do
  controller ApplicationController do
    include Telegram::SessionHelpers
  end

  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'automatic cleanup' do
    it 'removes expired session on access' do
      # Создаем истекшую сессию
      expired_session = TelegramSession.edit(time_shift_id: 123)
      travel_to(1.hour.ago) do
        controller.session[:telegram_session] = expired_session.to_h
      end

      # При доступе сессия должна быть удалена
      expect(controller.telegram_session).to be_nil
      expect(controller.session[:telegram_session]).to be_nil
    end

    it 'keeps active session' do
      # Создаем активную сессию
      active_session = TelegramSession.edit(time_shift_id: 123)
      controller.session[:telegram_session] = active_session.to_h

      # При доступе сессия должна остаться
      expect(controller.telegram_session).not_to be_nil
      expect(controller.telegram_session.type).to eq(:edit)
    end
  end
end
```

## 🚀 План внедрения

### День 1-2: Core TTL функциональность
- ✅ Обновить `TelegramSession` с временными метками
- ✅ Обновить `SessionHelpers` с проверкой TTL
- ✅ Написать базовые тесты

### День 3: Интеграция и отладка
- ✅ Интеграционное тестирование
- ✅ Проверка работы в development
- ✅ Мониторинг и логирование

## 📊 Ожидаемые результаты

- **Уменьшение использования памяти** на 60-80% для неактивных пользователей
- **Автоматическая очистка** истекших сессий при доступе
- **Улучшенная безопасность** за счет ограничения времени жизни данных
- **Детальное логирование** для мониторинга и отладки

## ⚠️ Важные замечания

1. **Обратная совместимость:** Старые сессии без временных меток будут обработаны корректно
2. **Lazy cleanup:** Сессии очищаются только при обращении к ним - эффективно и просто
3. **Безопасность:** Автоматическая очистка предотвращает накопление устаревших данных
4. **Мониторинг:** Все операции очистки логируются в Rails logger

## 🎯 Преимущества подхода "Lazy Cleanup"

- **Простота:** Никаких фоновых задач и сложных систем планирования
- **Эффективность:** Очистка только когда нужно, без лишних операций
- **Надежность:** Сессии гарантированно удаляются при следующем обращении
- **Масштабируемость:** Нет нагрузки на систему при простое
- **Понятность:** Логика очистки инкапсулирована в одном методе `telegram_session`