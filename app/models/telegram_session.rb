# frozen_string_literal: true

# Базовый класс для управления состоянием Telegram сессий
# Инкапсулирует все данные одной операции в единственный ключ session[:telegram_session]
class TelegramSession
  attr_accessor :type, :data

  VALID_TYPES = %i[edit add_user users_add_user add_time rename].freeze

  def initialize(type, data = {})
    @type = type.to_sym
    @data = data.with_indifferent_access
  end

  # Сериализация для сохранения в session
  def to_h
    {
      'type' => @type.to_s,
      'data' => @data
    }
  end

  # Десериализация из session
  def self.from_h(hash)
    return nil unless hash.is_a?(Hash)

    type = hash['type']&.to_sym
    data = hash['data'] || {}

    new(type, data)
  end

  # Валидация структуры данных
  def valid?
    VALID_TYPES.include?(@type) && @data.is_a?(Hash)
  end

  # Фабричный метод для создания сессии редактирования
  def self.edit(time_shift_id:)
    new(:edit, {
          time_shift_id: time_shift_id,
          field: nil,
          new_values: {}
        })
  end

  # Фабричный метод для создания сессии добавления пользователя
  def self.add_user(project_slug:)
    new(:add_user, {
          project_slug: project_slug,
          username: nil,
          role: nil
        })
  end

  # Фабричный метод для создания сессии добавления пользователя через users command
  def self.users_add_user(project_slug:)
    new(:users_add_user, {
          project_slug: project_slug,
          username: nil,
          role: nil
        })
  end

  # Фабричный метод для создания сессии добавления времени
  def self.add_time(project_id:)
    new(:add_time, {
          project_id: project_id
        })
  end

  # Фабричный метод для создания сессии переименования
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
