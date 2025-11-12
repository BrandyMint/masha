# frozen_string_literal: true

RSpec.shared_context 'telegram webhook base' do
  let!(:user) { users(:regular_user) }

  shared_context 'private chat' do
    let(:chat_id) { from_id }
  end

  shared_context 'public chat' do
    let(:chat_id) { -from_id }
  end

  shared_context 'authenticated user' do
    # Переменная telegram_user может быть переопределена в spec-е перед включением этого контекста
    # Если не переопределена, используем значение по умолчанию
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    # Устанавливаем chat данные для эмуляции Telegram API
    before(:each) do
      # Позволяем контроллеру получать chat данные для создания telegram_user
      allow(controller).to receive(:chat) do
        {
          'id' => telegram_user.id,
          'first_name' => telegram_user.first_name,
          'last_name' => telegram_user.last_name,
          'username' => telegram_user.username
        }
      end

      # Устанавливаем from данные
      allow(controller).to receive(:from) do
        {
          'id' => telegram_user.id
        }
      end

      # Очищаем @telegram_user переменную контроллера перед каждым тестом
      # Это предотвращает кеширование старого пользователя
      allow(controller).to receive(:instance_variable_set).and_call_original
      controller.instance_variable_set(:@telegram_user, nil)
    end
  end
end
