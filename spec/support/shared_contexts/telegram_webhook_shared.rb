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
    before do
      allow(controller).to receive(:current_user) { user }
    end
  end
end
