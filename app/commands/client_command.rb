# frozen_string_literal: true

# Deprecated: Use ClientsCommand instead
# This class is kept for backward compatibility and will be removed in a future version
class ClientCommand < ClientsCommand
  def call(*args)
    # Показываем предупреждение о переименовании перед выполнением команды
    return respond_with :message, text: t('telegram.commands.clients.deprecated_warning') do
      # Вызываем родительский метод после отправки предупреждения
      super
    end
  end
end
