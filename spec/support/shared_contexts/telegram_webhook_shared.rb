# frozen_string_literal: true

RSpec.shared_context 'telegram webhook base' do
  let!(:user) { create :user }

  shared_context 'private chat' do
    let(:chat_id) { from_id }
  end

  shared_context 'public chat' do
    let(:chat_id) { -from_id }
  end

  shared_context 'unauthenticated user' do
    # No additional setup needed - user is not logged in by default
  end

  shared_context 'authenticated user' do
    before do
      allow(controller).to receive(:current_user) { user }
    end
  end
end