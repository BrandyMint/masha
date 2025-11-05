# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::ProjectsCommand do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }
  let!(:projects) do
    [
      create(:project, name: 'Project', slug: 'project'),
      create(:project, name: 'Project2', slug: 'pr2')
    ]
  end

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:multiline).and_return('projects list')

    # Create memberships so user has access to projects
    projects.each { |project| create(:membership, user: user, project: project) }
  end

  describe '#call' do
    it 'responds with available projects' do
      command.call

      expect(controller).to have_received(:multiline).with('Доступные проекты:', nil)
      expect(controller).to have_received(:respond_with).with(:message, text: /projects list.*Project.*Project2/m)
    end
  end
end
