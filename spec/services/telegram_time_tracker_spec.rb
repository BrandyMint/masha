# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramTimeTracker do
  fixtures :users, :projects, :memberships, :time_shifts, :telegram_users

  let(:telegram_user) { telegram_users(:telegram_regular) }
  let(:project1) { projects(:project1) }
  let(:project2) { projects(:project2) }
  let(:project_with_digits) { projects(:project123) }

  describe '#parse_and_add' do
    context 'with valid inputs' do
      context 'standard format: hours project description' do
        it 'parses correctly' do
          message_parts = ['2.5', 'project1', 'working on feature']
          tracker = described_class.new(telegram_user, message_parts)

          result = tracker.parse_and_add
          expect(result[:success]).to be true
          expect(result[:message]).to include '✅ Отметили 2.5ч в проекте Project One'
        end
      end

      context 'reverse format: project hours description' do
        it 'parses correctly' do
          message_parts = ['project2', '1.5', 'bug fixing']
          tracker = described_class.new(telegram_user, message_parts)

          result = tracker.parse_and_add

          expect(result[:success]).to be true
          expect(result[:message]).to include '✅ Отметили 1.5ч в проекте Project Two'
        end
      end

      context 'project with digits' do
        it 'handles project123 2.5 format' do
          message_parts = ['project123', '2.5']
          tracker = described_class.new(telegram_user, message_parts)

          result = tracker.parse_and_add

          expect(result[:success]).to be true
          expect(result[:message]).to include '✅ Отметили 2.5ч в проекте Project 123'
        end

        it 'handles 2.5 project123 format' do
          message_parts = ['2.5', 'project123']
          tracker = described_class.new(telegram_user, message_parts)

          result = tracker.parse_and_add

          expect(result[:success]).to be true
          expect(result[:message]).to include '✅ Отметили 2.5ч в проекте Project 123'
        end
      end

      context 'with decimal comma' do
        it 'handles comma as decimal separator' do
          message_parts = ['1,5', 'project1']
          tracker = described_class.new(telegram_user, message_parts)

          result = tracker.parse_and_add

          expect(result[:success]).to be true
          expect(result[:message]).to include '✅ Отметили 1.5ч в проекте Project One'
        end
      end
    end

    context 'with ambiguous inputs' do
      context 'both parts are time' do
        it 'asks for clarification' do
          message_parts = ['2.5', '1.5']
          tracker = described_class.new(telegram_user, message_parts)

          result = tracker.parse_and_add
          expect(result[:error]).to include('❓ Не понял. Вы имели в виду:')
          expect(result[:error]).to include('2.5 часа в каком проекте?')
          expect(result[:error]).to include('1.5 часа в каком проекте?')
        end
      end

      context 'both parts are projects' do
        it 'asks for clarification' do
          message_parts = %w[project1 project2]
          tracker = described_class.new(telegram_user, message_parts)

          result = tracker.parse_and_add
          expect(result[:error]).to include('❓ Не понял. Вы имели в виду:')
          expect(result[:error]).to include("Проект 'project1' сколько часов?")
          expect(result[:error]).to include("Проект 'project2' сколько часов?")
        end
      end
    end

    context 'with invalid inputs' do
      context 'non-existent project' do
        it 'shows error with available projects' do
          message_parts = ['2.5', 'nonexistent']
          tracker = described_class.new(telegram_user, message_parts)

          result = tracker.parse_and_add
          expect(result[:error]).to include("Не найден проект 'nonexistent'")
          expect(result[:error]).to include('Доступные проекты:')
          expect(result[:error]).to include(/project1|project2|project123/)
        end
      end

      context 'invalid time format' do
        it 'shows error for invalid time' do
          message_parts = %w[abc project1]
          tracker = described_class.new(telegram_user, message_parts)

          result = tracker.parse_and_add
          expect(result[:error]).to include("Первый параметр 'abc' не похож на время")
        end
      end

      context 'too few parts' do
        it 'shows generic error' do
          message_parts = ['2.5']
          tracker = described_class.new(telegram_user, message_parts)

          result = tracker.parse_and_add
          expect(result[:error]).to eq('Я не Алиса, мне нужна конкретика. Жми /help')
        end
      end

      context 'time out of range' do
        it 'shows error for too much time' do
          message_parts = %w[25 project1]
          tracker = described_class.new(telegram_user, message_parts)

          result = tracker.parse_and_add
          expect(result[:error]).to include('Слишком много времени: 25.0. Максимум 24 часа')
        end

        it 'shows error for too little time' do
          message_parts = ['0.05', 'project1']
          tracker = described_class.new(telegram_user, message_parts)

          result = tracker.parse_and_add
          expect(result[:error]).to include('Слишком мало времени: 0.05. Минимум 0.1 часа')
        end
      end
    end

    context 'with typo in project name' do
      it 'suggests similar projects and auto-corrects' do
        message_parts = ['2.5', 'projec'] # typo: missing 't'
        tracker = described_class.new(telegram_user, message_parts)

        # Should work despite the typo - fuzzy matching finds project1
        result = tracker.parse_and_add
        expect(result[:success]).to be true
        expect(result[:message]).to include '✅ Отметили 2.5ч в проекте Project One'
      end

      it 'actually finds project with typo' do
        tracker = described_class.new(telegram_user, [])
        fuzzy_project = tracker.send(:find_project_fuzzy, 'projec')
        expect(fuzzy_project).not_to be_nil
        expect(fuzzy_project.slug).to eq('project1')
      end
    end
  end

  describe '#determine_hours_and_project' do
    let(:tracker) { described_class.new(telegram_user, []) }

    context 'when first part is time and second is project' do
      it 'returns correct order' do
        result = tracker.send(:determine_hours_and_project, '2.5', 'project1')
        expect(result[:hours]).to eq('2.5')
        expect(result[:project_slug]).to eq('project1')
      end
    end

    context 'when first part is project and second is time' do
      it 'returns correct order' do
        result = tracker.send(:determine_hours_and_project, 'project1', '1.5')
        expect(result[:hours]).to eq('1.5')
        expect(result[:project_slug]).to eq('project1')
      end
    end

    context 'with project containing digits' do
      it 'correctly identifies project vs time' do
        result = tracker.send(:determine_hours_and_project, '2.5', 'project123')
        expect(result[:hours]).to eq('2.5')
        expect(result[:project_slug]).to eq('project123')
      end
    end
  end

  describe '#time_format?' do
    let(:tracker) { described_class.new(telegram_user, []) }

    it 'accepts valid time formats' do
      expect(tracker.send(:time_format?, '2.5')).to be true
      expect(tracker.send(:time_format?, '1,5')).to be true
      expect(tracker.send(:time_format?, '8')).to be true
      expect(tracker.send(:time_format?, '0.5')).to be true
    end

    it 'rejects invalid time formats' do
      expect(tracker.send(:time_format?, 'abc')).to be false
      expect(tracker.send(:time_format?, '2.5.5')).to be false
      # NOTE: time_format? now accepts any positive number, range validation is separate
    end
  end

  describe '#add_time_entry' do
    let(:tracker) { described_class.new(telegram_user, []) }

    context 'with normal hours' do
      it 'creates time entry successfully' do
        result = tracker.send(:add_time_entry, 'project1', '2.5', 'test description')
        expect(result).to include('✅ Отметили 2.5ч в проекте Project One')
        expect(result).to include('📝 test description')
      end
    end

    context 'with many hours' do
      it 'shows warning' do
        result = tracker.send(:add_time_entry, 'project1', '15')
        expect(result).to include('✅ Отметили 15.0ч в проекте Project One')
        expect(result).to include('⚠️ Много часов за день (15.0)')
      end
    end

    context 'with few hours' do
      it 'shows info' do
        result = tracker.send(:add_time_entry, 'project1', '0.25')
        expect(result).to include('✅ Отметили 0.25ч в проекте Project One')
        expect(result).to include('ℹ️ Мало часов (0.25)')
      end
    end
  end
end
