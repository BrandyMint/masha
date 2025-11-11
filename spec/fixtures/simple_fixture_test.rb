# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Simple Fixture Test', type: :model do
  fixtures :users

  it 'loads user fixtures' do
    admin = users(:admin)
    expect(admin).to be_present
    expect(admin.name).to eq('Admin User')
  end

  it 'transactional fixtures work' do
    initial_count = User.count
    create(:user, name: 'Test User')

    expect(User.count).to eq(initial_count + 1)

    # После окончания теста транзакция откатится
    # и пользователь не сохранится в БД
  end
end