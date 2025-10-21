# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  describe '#message direct time tracking' do
    include_context 'private chat'
    include_context 'authenticated user'

    let!(:project) { create(:project, slug: 'testproject') }
    let!(:other_project) { create(:project, slug: 'otherproject') }

    before do
      create(:membership, user: user, project: project, role: :member)
      create(:membership, user: user, project: other_project, role: :member)
    end

    context 'with hours first format: {hours} {project_slug} [description]' do
      it 'creates time entry with description' do
        expect do
          dispatch_message '2.5 testproject работал над задачей'
        end.to change { project.time_shifts.count }.by(1)

        time_shift = project.time_shifts.last
        expect(time_shift.hours).to eq(2.5)
        expect(time_shift.description).to eq('работал над задачей')
        expect(time_shift.user).to eq(user)
        expect(time_shift.date).to eq(Time.zone.today)
      end

      it 'creates time entry without description' do
        expect do
          dispatch_message '3 testproject'
        end.to change { project.time_shifts.count }.by(1)

        time_shift = project.time_shifts.last
        expect(time_shift.hours).to eq(3.0)
        expect(time_shift.description).to eq('')
      end

      it 'handles decimal hours with comma' do
        expect do
          dispatch_message '1,5 testproject задача'
        end.to change { project.time_shifts.count }.by(1)

        time_shift = project.time_shifts.last
        expect(time_shift.hours).to eq(1.5)
      end

      it 'responds with success message' do
        expect do
          dispatch_message '2 testproject работа'
        end.to respond_with_message(/Отметили 2\.0ч в проекте #{project.name}/)
      end
    end

    context 'with project first format: {project_slug} {hours} [description]' do
      it 'creates time entry with description' do
        expect do
          dispatch_message 'testproject 4.5 важная работа'
        end.to change { project.time_shifts.count }.by(1)

        time_shift = project.time_shifts.last
        expect(time_shift.hours).to eq(4.5)
        expect(time_shift.description).to eq('важная работа')
      end

      it 'creates time entry without description' do
        expect do
          dispatch_message 'testproject 8'
        end.to change { project.time_shifts.count }.by(1)

        time_shift = project.time_shifts.last
        expect(time_shift.hours).to eq(8.0)
        expect(time_shift.description).to eq('')
      end

      it 'responds with success message' do
        expect do
          dispatch_message 'testproject 6 разработка'
        end.to respond_with_message(/Отметили 6\.0ч в проекте #{project.name}/)
      end
    end

    context 'with invalid formats' do
      it 'responds with error for non-numeric values' do
        expect do
          dispatch_message 'testproject abc описание'
        end.to respond_with_message(/Второй параметр 'abc' не похож на время/)
      end

      it 'responds with error for unknown project' do
        expect do
          dispatch_message '2 unknownproject описание'
        end.to respond_with_message(/Не найден проект 'unknownproject'/)
      end

      it 'responds with default message for too few parts' do
        expect do
          dispatch_message 'only_one_word'
        end.to respond_with_message(/Я не Алиса, мне нужна конкретика/)
      end

      it 'responds with default message for empty text' do
        expect do
          dispatch_message '   '
        end.to respond_with_message(/Я не Алиса, мне нужна конкретика/)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
