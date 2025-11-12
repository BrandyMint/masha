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
    let(:chat_id) { from_id }
  end
end
