# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::DayCommand do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }
  let(:project1) { create(:project, slug: 'project-a') }
  let(:project2) { create(:project, slug: 'project-b') }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:code) { |text| "```#{text}```" }
    allow(controller).to receive(:find_project) { |slug| user.available_projects.alive.find_by(slug: slug) }

    # Add user to projects
    user.set_role(:member, project1)
    user.set_role(:member, project2)
  end

  describe '#call' do
    context 'when there are no time shifts for today' do
      it 'returns message about no records' do
        command.call

        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'За сегодня еще нет записей времени. Добавьте время с помощью команды /add')
      end
    end

    context 'when there are time shifts for today' do
      let!(:shift1) { create(:time_shift, user: user, project: project1, hours: 2.5, date: Date.current, description: 'Task 1') }
      let!(:shift2) { create(:time_shift, user: user, project: project1, hours: 1.5, date: Date.current, description: 'Task 2') }
      let!(:shift3) { create(:time_shift, user: user, project: project2, hours: 3.0, date: Date.current, description: 'Task 3') }

      it 'returns table with all time shifts grouped by project' do
        command.call

        expect(controller).to have_received(:respond_with)
          .with(:message, hash_including(parse_mode: :Markdown))
      end

      it 'includes all projects in the response' do
        allow(controller).to receive(:code) do |text|
          expect(text).to include('project-a')
          expect(text).to include('project-b')
          expect(text).to include('2.5')
          expect(text).to include('1.5')
          expect(text).to include('3.0')
          expect(text).to include('Итого за день')
          "```#{text}```"
        end

        command.call
      end
    end

    context 'with project filter' do
      let!(:shift1) { create(:time_shift, user: user, project: project1, hours: 2.5, date: Date.current, description: 'Task 1') }
      let!(:shift2) { create(:time_shift, user: user, project: project2, hours: 3.0, date: Date.current, description: 'Task 3') }

      it 'returns only shifts for specified project' do
        allow(controller).to receive(:code) do |text|
          expect(text).to include('project-a')
          expect(text).not_to include('project-b')
          expect(text).to include('2.5')
          expect(text).not_to include('3.0')
          "```#{text}```"
        end

        command.call('project-a')
      end

      it 'returns error for non-existent project' do
        command.call('nonexistent')

        expect(controller).to have_received(:respond_with)
          .with(:message, text: /Не найден проект 'nonexistent'/)
      end
    end

    context 'with no shifts for filtered project' do
      let!(:shift) { create(:time_shift, user: user, project: project1, hours: 2.5, date: Date.current, description: 'Task 1') }

      it 'returns message about no records for project' do
        command.call('project-b')

        expect(controller).to have_received(:respond_with)
          .with(:message, text: "Нет записей времени по проекту 'project-b' за сегодня")
      end
    end

    context 'when time shift has no description' do
      let!(:shift) { create(:time_shift, user: user, project: project1, hours: 2.5, date: Date.current, description: nil) }

      it 'handles empty description correctly' do
        allow(controller).to receive(:code) do |text|
          expect(text).to include('project-a')
          expect(text).to include('·')
          "```#{text}```"
        end

        command.call
      end
    end
  end

  describe '#build_day_report' do
    let(:time_shifts) do
      [
        build(:time_shift, project: project1, hours: 2.5, description: 'Task 1'),
        build(:time_shift, project: project1, hours: 1.5, description: 'Task 2'),
        build(:time_shift, project: project2, hours: 3.0, description: 'Task 3')
      ]
    end

    it 'groups shifts by project and calculates totals' do
      result = command.send(:build_day_report, time_shifts, nil, Date.current)

      expect(result).to include('project-a')
      expect(result).to include('project-b')
      expect(result).to include('7.0') # Total hours
      expect(result).to include('4.0') # project-a total
      expect(result).to include('3.0') # project-b total
    end

    it 'includes title with date when no project filter' do
      result = command.send(:build_day_report, time_shifts, nil, Date.current)

      expect(result).to include("Часы за #{Date.current}")
    end

    it 'includes title with project name when project filter is applied' do
      result = command.send(:build_day_report, time_shifts, 'project-a', Date.current)

      expect(result).to include("Часы по проекту 'project-a' за #{Date.current}")
    end
  end
end
