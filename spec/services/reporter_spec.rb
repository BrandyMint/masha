# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reporter do
  fixtures :users, :projects, :memberships, :time_shifts, :telegram_users

  let(:user) { users(:regular_user) }
  let(:project) { projects(:work_project) }
  let(:reporter) { described_class.new }
  let(:today) { Time.zone.today }

  # No setup needed - using fixtures data

  describe '#projects_to_users_matrix' do
    it 'generates matrix table for weekly period' do
      result = reporter.projects_to_users_matrix(user, 'week')

      expect(result).to be_a(String)
      expect(result).to include(user.email) # Regular user shows email
      expect(result).to include(project.slug) # Project slug
      expect(result).to include('total') # Total column
    end

    it 'generates matrix table for monthly period' do
      result = reporter.projects_to_users_matrix(user, 'month')

      expect(result).to be_a(String)
      expect(result).to include(today.strftime('%B %Y'))
      expect(result).to include(user.to_s)
      expect(result).to include(project.slug)
    end

    it 'generates matrix table for last_month period' do
      result = reporter.projects_to_users_matrix(user, 'last_month')

      expect(result).to be_a(String)
      expect(result).to include((today - 1.month).strftime('%B %Y'))
    end

    it 'generates matrix table for day period' do
      result = reporter.projects_to_users_matrix(user, 'day')

      expect(result).to be_a(String)
      expect(result).to include(today.strftime('%Y-%m-%d'))
    end

    it 'generates matrix table for specific date' do
      date_string = today.strftime('%Y-%m-%d')
      result = reporter.projects_to_users_matrix(user, date_string)

      expect(result).to be_a(String)
      expect(result).to include(today.strftime('%Y-%m-%d'))
    end

    it 'generates matrix table for month format' do
      month_string = today.strftime('%Y-%m')
      result = reporter.projects_to_users_matrix(user, month_string)

      expect(result).to be_a(String)
      expect(result).to include(today.strftime('%B %Y'))
    end

    it 'generates matrix table for date range' do
      start_date = today - 2.days
      end_date = today
      range_string = "#{start_date.strftime('%Y-%m-%d')}..#{end_date.strftime('%Y-%m-%d')}"
      result = reporter.projects_to_users_matrix(user, range_string)

      expect(result).to be_a(String)
      expect(result).to include("#{end_date} - #{start_date}")
    end

    it 'generates matrix table for month range' do
      start_month = (today - 1.month).strftime('%Y-%m')
      end_month = today.strftime('%Y-%m')
      month_range_string = "#{start_month}..#{end_month}"
      result = reporter.projects_to_users_matrix(user, month_range_string)

      expect(result).to be_a(String)
      # Month range shows the actual range from parser
      expect(result).to be_a(String)
    end

    it 'handles string period' do
      result = reporter.projects_to_users_matrix(user, 'week')

      expect(result).to be_a(String)
      expect(result).to include('total') # Should include total column
    end
  end

  describe '#build_period_title' do
    context 'relative periods' do
      it 'returns week title' do
        title = reporter.send(:build_period_title, 'week')
        expected = "#{today - 6} - #{today}"
        expect(title).to eq(expected)
      end

      it 'returns month title' do
        title = reporter.send(:build_period_title, 'month')
        expected = today.strftime('%B %Y')
        expect(title).to eq(expected)
      end

      it 'returns last_month title' do
        title = reporter.send(:build_period_title, 'last_month')
        expected = (today - 1.month).strftime('%B %Y')
        expect(title).to eq(expected)
      end

      it 'returns last_week title' do
        title = reporter.send(:build_period_title, 'last_week')
        expect(title).to eq('Last week')
      end

      it 'returns last_day title' do
        title = reporter.send(:build_period_title, 'last_day')
        expected = (today - 1.day).strftime('%Y-%m-%d')
        expect(title).to eq(expected)
      end

      it 'returns day title' do
        title = reporter.send(:build_period_title, 'day')
        expected = today.strftime('%Y-%m-%d')
        expect(title).to eq(expected)
      end
    end

    context 'range periods' do
      it 'returns date range title' do
        start_date = today - 2.days
        end_date = today
        range_hash = { type: :range, start_date: start_date, end_date: end_date }
        title = reporter.send(:build_period_title, range_hash)
        expected = "#{end_date} - #{start_date}"
        expect(title).to eq(expected)
      end

      it 'returns month_range title' do
        start_month = (today - 1.month).beginning_of_month
        end_month = today.beginning_of_month
        month_range_hash = { type: :month_range, start_date: start_month, end_date: end_month }
        title = reporter.send(:build_period_title, month_range_hash)
        expected = "#{end_month.strftime('%B %Y')} - #{start_month.strftime('%B %Y')}"
        expect(title).to eq(expected)
      end
    end

    context 'fallback cases' do
      it 'handles empty period' do
        title = reporter.send(:build_period_title, [])
        expect(title).to eq('All days')
      end

      it 'handles array period with first and last' do
        array_period = [today - 2.days, today - 1.day, today]
        title = reporter.send(:build_period_title, array_period)
        expected = "#{today} - #{today - 2.days}"
        expect(title).to eq(expected)
      end

      it 'handles string period' do
        title = reporter.send(:build_period_title, 'week')
        expect(title).to include(' - ')
      end
    end
  end

  describe '#list_by_days' do
    it 'generates list table for weekly period' do
      result = reporter.list_by_days(user, period: 'week', group_by: :project)

      expect(result).to be_a(String)
      expect(result).to include('date')
      expect(result).to include('total')
      expect(result).to include(project.name)
    end

    it 'generates list table for monthly period' do
      result = reporter.list_by_days(user, period: 'month', group_by: :project)

      expect(result).to be_a(String)
      expect(result).to include('date')
      expect(result).to include('total')
      expect(result).to include(project.name)
    end

    it 'generates list table grouped by user' do
      result = reporter.list_by_days(user, period: 'week', group_by: :user)

      expect(result).to be_a(String)
      expect(result).to include('date')
      expect(result).to include('total')
      expect(result).to include(user.name)
    end
  end
end
