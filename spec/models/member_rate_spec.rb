# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MemberRate, type: :model do
  let(:member_rate) { build(:member_rate) }

  describe 'associations' do
    it 'belongs to project' do
      expect(member_rate).to respond_to(:project)
    end

    it 'belongs to user' do
      expect(member_rate).to respond_to(:user)
    end
  end

  describe '.CURRENCIES' do
    it 'contains expected currencies' do
      expect(MemberRate::CURRENCIES).to eq(%w[RUB EUR USD])
    end
  end

  describe '#rate_with_currency' do
    context 'with hourly_rate present' do
      it 'returns formatted rate string' do
        member_rate.hourly_rate = 50.5
        member_rate.currency = 'USD'
        expect(member_rate.rate_with_currency).to eq('50.5 USD')
      end
    end

    context 'without hourly_rate' do
      it 'returns nil' do
        member_rate.hourly_rate = nil
        expect(member_rate.rate_with_currency).to be_nil
      end
    end
  end

  describe 'validations' do
    it 'accepts valid hourly_rate' do
      member_rate.hourly_rate = 100.50
      expect(member_rate).to be_valid
    end

    it 'rejects negative hourly_rate' do
      member_rate.hourly_rate = -10
      expect(member_rate).not_to be_valid
      expect(member_rate.errors[:hourly_rate]).to include('может иметь значение большее или равное 0')
    end

    it 'accepts valid currencies' do
      %w[RUB EUR USD].each do |currency|
        member_rate.currency = currency
        expect(member_rate).to be_valid, "Expected #{currency} to be valid"
      end
    end

    it 'rejects invalid currency' do
      member_rate.currency = 'GBP'
      expect(member_rate).not_to be_valid
      expect(member_rate.errors[:currency]).to include('имеет непредусмотренное значение')
    end

    it 'validates uniqueness of project-user pair' do
      existing_rate = create(:member_rate)
      new_rate = build(:member_rate, project: existing_rate.project, user: existing_rate.user)
      expect(new_rate).not_to be_valid
      expect(new_rate.errors[:project_id]).to include('уже существует')
    end
  end
end
