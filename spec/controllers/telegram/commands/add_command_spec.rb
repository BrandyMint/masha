# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::AddCommand do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }
  let!(:project) { create(:project, name: 'Test Project', slug: 'test') }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:save_context)
    allow(controller).to receive(:find_project).and_return(project)

    # Create membership so user has access to project
    create(:membership, user: user, project: project)
  end

  describe '#call' do
    context 'when project_slug is not provided' do
      it 'shows project selection' do
        command.call

        expect(controller).to have_received(:save_context).with(:add_callback_query)
        expect(controller).to have_received(:respond_with).with(
          :message,
          text: 'Выберите проект, в котором отметить время:',
          reply_markup: hash_including(:inline_keyboard)
        )
      end
    end

    context 'when project_slug is provided' do
      before do
        allow(project).to receive(:present?).and_return(true)
        allow(project).to receive(:time_shifts).and_return(project.time_shifts)
      end

      it 'adds time to project' do
        expect do
          command.call('test_project', '2.5', 'working on feature')
        end.to change { project.time_shifts.count }.by(1)

        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'Отметили в Test Project 2.5 часов')
      end

      context 'when project is not found' do
        before do
          allow(controller).to receive(:find_project).and_return(nil)
        end

        it 'responds with error message' do
          command.call('nonexistent_project', '2.5', 'working on feature')

          expect(controller).to have_received(:respond_with)
            .with(:message, text: include('Не найден такой проект'))
        end
      end
    end
  end
end
