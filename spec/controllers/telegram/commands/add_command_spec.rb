# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::AddCommand, type: :controller do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:save_context)
    allow(controller).to receive(:find_project).and_return(project)
  end

  describe '#call' do
    context 'when project_slug is not provided' do
      let(:available_projects) { double('available_projects') }

      before do
        allow(user).to receive(:available_projects).and_return(available_projects)
        allow(available_projects).to receive(:alive).and_return([project])
        allow(project).to receive(:name).and_return('Test Project')
        allow(project).to receive(:slug).and_return('test')
      end

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
      let(:time_shifts) { double('time_shifts') }

      before do
        allow(project).to receive(:time_shifts).and_return(time_shifts)
        allow(time_shifts).to receive(:create!)
        allow(project).to receive(:name).and_return('Test Project')
        allow(project).to receive(:present?).and_return(true)
      end

      it 'adds time to project' do
        command.call('test_project', '2.5', 'working on feature')

        expect(time_shifts).to have_received(:create!).with(
          date: Time.zone.today,
          hours: 2.5,
          description: 'working on feature',
          user: user
        )
        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'Отметили в Test Project 2.5 часов')
      end
    end
  end
end
