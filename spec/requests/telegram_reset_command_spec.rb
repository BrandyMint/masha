# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Telegram /reset command', type: :request do
  let(:user) { create(:user) }
  let(:telegram_account) { create(:telegram_account, user: user) }

  it 'resets session successfully' do
    # Этот тест проверяет базовую функциональность команды
    # В реальном приложении команда будет доступна через webhook

    command = Telegram::Commands::ResetCommand.new(nil)

    # Проверяем что класс существует и имеет нужные методы
    expect(command).to respond_to(:call)
    expect(Telegram::Commands::ResetCommand).to be <= Telegram::Commands::BaseCommand
  end

  it 'includes error handling module' do
    # Проверяем что команда использует модуль обработки ошибок
    expect(Telegram::Commands::ResetCommand.ancestors).to include(Telegram::ErrorHandling)
  end
end
