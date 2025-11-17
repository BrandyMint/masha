# frozen_string_literal: true

# Тест для проверки что fixtures загружаются корректно
# Этот тест должен работать очень быстро с transactional fixtures

require 'rails_helper'

RSpec.describe 'Fixtures Loading', type: :model do
  describe 'User fixtures' do
    it 'loads admin user correctly' do
      admin = users(:admin)
      expect(admin).to be_present
      expect(admin.name).to eq('Admin User')
      expect(admin.email).to eq('admin@example.com')
      expect(admin.is_root).to be true
    end

    it 'loads regular user correctly' do
      user = users(:regular_user)
      expect(user).to be_present
      expect(user.name).to eq('Regular User')
      expect(user.email).to eq('regular@example.com')
      expect(user.is_root).to be false
    end

    it 'loads user with telegram correctly' do
      user = users(:user_with_telegram)
      expect(user).to be_present
      expect(user.telegram_user_id).to eq(987_654_321)
      expect(user.name).to eq('Telegram User')
    end
  end

  describe 'Project fixtures' do
    it 'loads work project correctly' do
      project = projects(:work_project)
      expect(project).to be_present
      expect(project.slug).to eq('work-project')
      expect(project.active).to be true
    end

    it 'loads inactive project correctly' do
      project = projects(:inactive_project)
      expect(project).to be_present
      expect(project.active).to be false
    end
  end

  describe 'Membership fixtures' do
    it 'loads admin ownership correctly' do
      membership = memberships(:admin_work)
      expect(membership).to be_present
      expect(membership.user).to eq(users(:admin))
      expect(membership.project).to eq(projects(:work_project))
      expect(membership.role).to eq(:owner)
    end

    it 'loads regular membership correctly' do
      membership = memberships(:regular_work)
      expect(membership).to be_present
      expect(membership.role).to eq(:member)
    end
  end

  describe 'Telegram user fixtures' do
    it 'loads telegram admin correctly' do
      telegram_user = telegram_users(:telegram_admin)
      expect(telegram_user).to be_present
      expect(telegram_user.id).to eq(123_456_789)
      expect(telegram_user.username).to eq('admin_user')
    end

    it 'loads telegram regular correctly' do
      telegram_user = telegram_users(:telegram_regular)
      expect(telegram_user).to be_present
      expect(telegram_user.id).to eq(987_654_321)
    end
  end

  describe 'TimeShift fixtures' do
    it 'loads basic time shift correctly' do
      time_shift = time_shifts(:work_time_today)
      expect(time_shift).to be_present
      expect(time_shift.user).to eq(users(:regular_user))
      expect(time_shift.project).to eq(projects(:work_project))
      expect(time_shift.hours).to eq(2.0)
      expect(time_shift.date).to eq(Date.current)
    end
  end

  describe 'Cross-fixture relationships' do
    it 'maintains correct relationships between fixtures' do
      admin = users(:admin)
      work_project = projects(:work_project)
      admin_membership = memberships(:admin_work)

      expect(admin_membership.user).to eq(admin)
      expect(admin_membership.project).to eq(work_project)
    end

    it 'connects telegram users correctly' do
      user = users(:user_with_telegram)
      telegram_user = telegram_users(:telegram_regular)

      expect(user.telegram_user_id).to eq(telegram_user.id)
    end
  end

  describe 'Performance test' do
    it 'loads fixtures quickly' do
      start_time = Time.zone.now

      # Загружаем несколько fixtures
      5.times do
        users(:admin)
        projects(:work_project)
        memberships(:admin_work)
        telegram_users(:telegram_admin)
        time_shifts(:work_time_today)
      end

      end_time = Time.zone.now
      duration = end_time - start_time

      # Должно быть очень быстро с transactional fixtures
      expect(duration).to be > 0.001
    end
  end
end
