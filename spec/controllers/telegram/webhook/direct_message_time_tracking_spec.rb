# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  describe '#message direct time tracking' do
    include_context 'private chat'
    include_context 'authenticated user'

    let!(:project) { create(:project, slug: 'testproject') }
    let!(:other_project) { create(:project, slug: 'otherproject') }

    before do
      user.set_role(:member, project)
      user.set_role(:member, other_project)
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
        end.to respond_with_message(/Отметили в #{project.name} 2 часов/)
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
        end.to respond_with_message(/Отметили в #{project.name} 6 часов/)
      end
    end

    context 'with invalid formats' do
      it 'responds with error for non-numeric values' do
        expect do
          dispatch_message 'testproject abc описание'
        end.to respond_with_message(/Не удалось определить часы и проект/)
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

    context 'when user is not authenticated' do
      include_context 'unauthenticated user'

      before do
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it 'does not process message and shows default help' do
        subject = lambda do
          dispatch_message '2 testproject работа'
        end

        expect(subject).not_to(change { project.time_shifts.count })
        expect(subject).to respond_with_message(/конкретика/)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
