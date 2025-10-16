# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::RenameCommand do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'Old Project', slug: 'old-project') }
  let(:membership) { create(:membership, user: user, project: project, role: :owner) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:respond_with)
    allow(command).to receive(:find_project).and_return(project)
    allow(controller).to receive(:save_context)
    allow(controller).to receive(:multiline)
  end

  describe '#call' do
    context 'with project_slug and new_name' do
      it 'renames project directly' do
        expect(command).to receive(:rename_project_directly).with('test-project', 'New Project Name')

        command.call('test-project', 'New', 'Project', 'Name')
      end
    end

    context 'without arguments' do
      it 'shows projects selection' do
        expect(command).to receive(:show_projects_selection)

        command.call
      end
    end
  end
end

RSpec.describe Telegram::Commands::RenameCommand, '#rename_project_directly' do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'Old Project', slug: 'old-project') }
  let(:membership) { create(:membership, user: user, project: project, role: :owner) }
  let(:service) { instance_double(ProjectRenameService) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:respond_with)
    allow(command).to receive(:find_project).with('old-project').and_return(project)
    allow(ProjectRenameService).to receive(:new).and_return(service)
  end

  context 'with valid data' do
    it 'renames project successfully' do
      expect(service).to receive(:call).with(user, project, 'New Project').and_return(
        { success: true, message: 'success message' }
      )
      expect(controller).to receive(:respond_with).with(:message, text: 'success message')

      command.send(:rename_project_directly, 'old-project', 'New Project')
    end
  end

  context 'when project not found' do
    before do
      allow(command).to receive(:find_project).with('old-project').and_return(nil)
    end

    it 'responds with project not found error' do
      expect(controller).to receive(:respond_with).with(
        :message,
        text: "Проект с slug 'old-project' не найден или недоступен"
      )
      expect(service).not_to receive(:call)

      command.send(:rename_project_directly, 'old-project', 'New Project')
    end
  end

  context 'when service returns error' do
    it 'responds with service error message' do
      expect(service).to receive(:call).with(user, project, 'New Project').and_return(
        { success: false, message: 'Error message' }
      )
      expect(controller).to receive(:respond_with).with(:message, text: 'Error message')

      command.send(:rename_project_directly, 'old-project', 'New Project')
    end
  end
end

RSpec.describe Telegram::Commands::RenameCommand, '#show_projects_selection' do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'Old Project', slug: 'old-project') }
  let(:membership) { create(:membership, user: user, project: project, role: :owner) }
  let(:service) { instance_double(ProjectRenameService) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:save_context)
    allow(ProjectRenameService).to receive(:new).and_return(service)
  end

  context 'when user has manageable projects' do
    let(:another_project) { create(:project, name: 'Another Project', slug: 'another-project') }
    let(:another_membership) { create(:membership, user: user, project: another_project, role: :owner) }

    it 'shows projects with inline keyboard' do
      manageable_projects = [project, another_project]
      expect(service).to receive(:manageable_projects).with(user).and_return(manageable_projects)
      expect(controller).to receive(:save_context).with(:rename_project_callback_query)
      expect(controller).to receive(:respond_with) do |type, options|
        expect(type).to eq(:message)
        expect(options[:text]).to eq('Выберите проект для переименования:')
        expect(options[:reply_markup][:inline_keyboard]).to be_an(Array)
      end

      command.send(:show_projects_selection)
    end
  end

  context 'when user has no manageable projects' do
    let(:viewer_membership) { create(:membership, user: user, project: project, role: :viewer) }

    before do
      membership.destroy
    end

    it 'responds with no projects message' do
      expect(service).to receive(:manageable_projects).with(user).and_return([])
      expect(controller).to receive(:respond_with).with(
        :message,
        text: 'У вас нет проектов, которые вы можете переименовывать. Только владельцы (owners) могут переименовывать проекты.'
      )
      expect(controller).not_to receive(:save_context)

      command.send(:show_projects_selection)
    end
  end
end
