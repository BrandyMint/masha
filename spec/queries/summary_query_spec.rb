# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SummaryQuery do
  fixtures :time_shifts

  let(:user) { users(:regular_user) }
  let(:project) { projects(:work_project) }
  let(:today) { Time.zone.today }

  # Используем существующие time_shift fixtures: work_time_today и work_time_yesterday
  # которые уже содержат необходимые данные для regular_user в work_project

  describe '.for_user' do
    it 'creates query with parsed period' do
      expected_period = (today - 6)..today
      query = described_class.for_user(user, period: 'week')

      expect(query).to be_a(described_class)
      expect(query.send(:period)).to eq(expected_period)
    end

    it 'passes nil period to parser when no period specified' do
      query = described_class.for_user(user)

      expect(query.send(:period)).to be_a(Range)
      expect(query.send(:period)).to include(today)
    end
  end

  describe '#build_period' do
    let(:query) { described_class.new(users: [user], projects: [project]) }

    context 'relative periods' do
      it 'builds week period' do
        result = query.send(:build_period, 'week')
        expect(result).to eq((today - 6)..today)
      end

      it 'builds month period' do
        result = query.send(:build_period, 'month')
        expect(result).to eq(today.beginning_of_month..today)
      end

      it 'builds last_month period' do
        result = query.send(:build_period, 'last_month')
        expected = (today - 1.month).beginning_of_month..(today - 1.month).end_of_month
        expect(result).to eq(expected)
      end

      it 'builds last_week period' do
        result = query.send(:build_period, 'last_week')
        expected = (today - 1.week).beginning_of_week..(today - 1.week).end_of_week
        expect(result).to eq(expected)
      end

      it 'builds last_day period' do
        result = query.send(:build_period, 'last_day')
        expect(result).to eq((today - 1.day)..(today - 1.day))
      end

      it 'builds day period' do
        result = query.send(:build_period, 'day')
        expect(result).to eq(today..today)
      end
    end

    context 'hash periods' do
      it 'builds date period' do
        date_hash = { type: :date, date: today }
        result = query.send(:build_period, date_hash)
        expect(result).to eq(today..today)
      end

      it 'builds month period from hash' do
        month_date = today.beginning_of_month
        month_hash = { type: :month, date: month_date }
        result = query.send(:build_period, month_hash)
        expect(result).to eq(month_date.beginning_of_month..month_date.end_of_month)
      end

      it 'builds range period' do
        start_date = today - 2.days
        end_date = today
        range_hash = { type: :range, start_date: start_date, end_date: end_date }
        result = query.send(:build_period, range_hash)
        expect(result).to eq(start_date..end_date)
      end

      it 'builds month_range period' do
        start_month = (today - 1.month).beginning_of_month
        end_month = today.beginning_of_month
        month_range_hash = { type: :month_range, start_date: start_month, end_date: end_month }
        result = query.send(:build_period, month_range_hash)
        expect(result).to eq(start_month..end_month.end_of_month)
      end
    end

    context 'backward compatibility' do
      it 'handles enumerable period' do
        enum_period = (today - 2.days..today).to_a
        result = query.send(:build_period, enum_period)
        expect(result).to eq(enum_period)
      end

      it 'handles old :month symbol' do
        result = query.send(:build_period, :month)
        expect(result).to be_a(Array)
        expect(result.first).to be_a(Date)
        expect(result.last).to be_a(Date)
      end

      it 'handles old :week symbol' do
        result = query.send(:build_period, :week)
        expect(result).to be_a(Array)
        expect(result.first).to be_a(Date)
        expect(result.last).to be_a(Date)
      end
    end
  end

  describe '#projects_to_users_matrix' do
    let(:query) { described_class.for_user(user, period: 'week') }

    it 'returns matrix structure' do
      result = query.projects_to_users_matrix

      expect(result).to have_key(:matrix)
      expect(result).to have_key(:period)
      expect(result).to have_key(:projects)
      expect(result).to have_key(:users)
      expect(result).to have_key(:days)
    end

    it 'includes project in matrix' do
      result = query.projects_to_users_matrix

      expect(result[:projects]).to include(project)
      expect(result[:matrix][project]).to have_key(user)
      # Учитываем что есть данные из других проектов в пределах недели
      expect(result[:matrix][project][user]).to be > 0
    end

    it 'includes totals' do
      result = query.projects_to_users_matrix

      expect(result[:matrix][:total]).to have_key(user)
      expect(result[:matrix][:total][user]).to be > 5
      expect(result[:matrix][project][:total]).to be > 5
    end
  end

  describe '#list_by_days' do
    let(:query) { described_class.for_user(user, period: 'week', group_by: :project) }

    it 'returns list structure' do
      result = query.list_by_days

      expect(result).to have_key(:columns)
      expect(result).to have_key(:total)
      expect(result).to have_key(:total_by_date)
      expect(result).to have_key(:total_by_column)
      expect(result).to have_key(:days)
      expect(result).to have_key(:group_by)
      expect(result).to have_key(:period)
    end

    it 'includes daily totals' do
      result = query.list_by_days

      expect(result[:total_by_date][today]).to be > 0
      expect(result[:total_by_date][today - 1.day]).to be > 0
    end

    it 'includes column totals' do
      result = query.list_by_days

      expect(result[:total_by_column][project.to_s]).to be > 0
    end

    it 'includes total hours' do
      result = query.list_by_days

      expect(result[:total]).to be > 0
    end
  end
end
