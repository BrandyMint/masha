# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::ProjectsCommand, type: :controller do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }
  let(:projects) { create_list(:project, 2) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:multiline).and_return('projects list')

    available_projects = double('available_projects')
    allow(user).to receive(:available_projects).and_return(available_projects)
    allow(available_projects).to receive(:alive).and_return(projects)
    allow(projects).to receive(:join).with(', ').and_return('project1, project2')
  end

  describe '#call' do
    it 'responds with available projects' do
      command.call

      expect(controller).to have_received(:multiline).with('Доступные проекты:', nil, 'project1, project2')
      expect(controller).to have_received(:respond_with).with(:message, text: 'projects list')
    end
  end
end
