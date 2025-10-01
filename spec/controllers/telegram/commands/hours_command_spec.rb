# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::HoursCommand do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }
  let(:project1) { create(:project, slug: 'proj1') }
  let(:project2) { create(:project, slug: 'proj2') }

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
    context 'with no time shifts' do
      it 'returns message about no records' do
        command.call

        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'Нет записей времени за последние 3 месяца')
      end
    end

    context 'with time shifts in last 3 months' do
      let!(:shift1) { create(:time_shift, user: user, project: project1, hours: 2.5, date: 1.month.ago) }
      let!(:shift2) { create(:time_shift, user: user, project: project2, hours: 3.0, date: 2.weeks.ago) }
      let!(:shift3) { create(:time_shift, user: user, project: project1, hours: 1.5, date: 1.week.ago) }

      it 'returns table with all time shifts' do
        command.call

        expect(controller).to have_received(:respond_with)
          .with(:message, hash_including(parse_mode: :Markdown))
      end

      it 'includes all shifts in the response' do
        allow(controller).to receive(:code) do |text|
          expect(text).to include('proj1')
          expect(text).to include('proj2')
          expect(text).to include('2.5')
          expect(text).to include('3.0')
          expect(text).to include('1.5')
          expect(text).to include('Всего')
          "```#{text}```"
        end

        command.call
      end
    end

    context 'with time shifts older than 3 months' do
      let!(:old_shift) { create(:time_shift, user: user, project: project1, hours: 5.0, date: 4.months.ago) }
      let!(:recent_shift) { create(:time_shift, user: user, project: project1, hours: 2.0, date: 1.week.ago) }

      it 'only includes shifts from last 3 months' do
        allow(controller).to receive(:code) do |text|
          expect(text).to include('2.0')
          expect(text).not_to include('5.0')
          "```#{text}```"
        end

        command.call
      end
    end

    context 'with project filter' do
      let!(:shift1) { create(:time_shift, user: user, project: project1, hours: 2.5, date: 1.month.ago) }
      let!(:shift2) { create(:time_shift, user: user, project: project2, hours: 3.0, date: 2.weeks.ago) }

      it 'returns only shifts for specified project' do
        allow(controller).to receive(:code) do |text|
          expect(text).to include('proj1')
          expect(text).not_to include('proj2')
          expect(text).to include('2.5')
          expect(text).not_to include('3.0')
          "```#{text}```"
        end

        command.call('proj1')
      end

      it 'returns error for non-existent project' do
        command.call('nonexistent')

        expect(controller).to have_received(:respond_with)
          .with(:message, text: /Не найден проект 'nonexistent'/)
      end
    end

    context 'with no shifts for filtered project' do
      let!(:shift) { create(:time_shift, user: user, project: project1, hours: 2.5, date: 1.month.ago) }

      it 'returns message about no records for project' do
        command.call('proj2')

        expect(controller).to have_received(:respond_with)
          .with(:message, text: "Нет записей времени по проекту 'proj2' за последние 3 месяца")
      end
    end
  end
end
