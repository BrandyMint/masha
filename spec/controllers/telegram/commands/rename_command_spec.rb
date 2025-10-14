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
    allow(controller).to receive(:find_project).and_return(project)
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

  describe '#rename_project_directly' do
    context 'with valid data' do
      before do
        allow(command).to receive(:can_rename_project?).and_return(true)
        allow(Project).to receive(:exists?).with(name: 'New Project').and_return(false)
      end

      it 'renames project successfully' do
        expect(project).to receive(:update!).with(name: 'New Project')
        expect(controller).to receive(:multiline).and_return('success message')
        expect(controller).to receive(:respond_with).with(:message, text: 'success message')

        command.send(:rename_project_directly, 'old-project', 'New Project')
      end
    end

    context 'with blank new_name' do
      it 'responds with error message' do
        expect(controller).to receive(:respond_with).with(
          :message,
          text: 'Укажите новое название проекта. Например: /rename project-slug "Новое название"'
        )

        command.send(:rename_project_directly, 'old-project', '')
      end
    end

    context 'when project not found' do
      before do
        allow(controller).to receive(:find_project).and_return(nil)
      end

      it 'responds with project not found error' do
        expect(controller).to receive(:respond_with).with(
          :message,
          text: "Проект с slug 'old-project' не найден или недоступен"
        )

        command.send(:rename_project_directly, 'old-project', 'New Project')
      end
    end

    context 'when user lacks permission' do
      before do
        allow(command).to receive(:can_rename_project?).and_return(false)
      end

      it 'responds with permission error' do
        expect(controller).to receive(:respond_with).with(
          :message,
          text: 'У вас нет прав для переименования этого проекта. Только владелец (owner) может переименовывать проекты.'
        )

        command.send(:rename_project_directly, 'old-project', 'New Project')
      end
    end

    context 'when name is too short' do
      before do
        allow(command).to receive(:can_rename_project?).and_return(true)
      end

      it 'responds with validation error' do
        expect(controller).to receive(:respond_with).with(
          :message,
          text: 'Название проекта должно содержать минимум 2 символа'
        )

        command.send(:rename_project_directly, 'old-project', 'A')
      end
    end

    context 'when name is too long' do
      before do
        allow(command).to receive(:can_rename_project?).and_return(true)
        long_name = 'A' * 256
        expect(controller).to receive(:respond_with).with(
          :message,
          text: 'Название проекта не может быть длиннее 255 символов'
        )

        command.send(:rename_project_directly, 'old-project', long_name)
      end
    end

    context 'when project name already exists' do
      before do
        allow(command).to receive(:can_rename_project?).and_return(true)
        allow(Project).to receive(:exists?).with(name: 'Existing Project').and_return(true)
      end

      it 'responds with duplicate name error' do
        expect(controller).to receive(:respond_with).with(
          :message,
          text: 'Проект с таким названием уже существует'
        )

        command.send(:rename_project_directly, 'old-project', 'Existing Project')
      end
    end
  end

  describe '#show_projects_selection' do
    context 'when user has manageable projects' do
      let(:another_project) { create(:project, name: 'Another Project', slug: 'another-project') }
      let(:another_membership) { create(:membership, user: user, project: another_project, role: :owner) }

      it 'shows projects with inline keyboard' do
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
        expect(controller).to receive(:respond_with).with(
          :message,
          text: 'У вас нет проектов, которые вы можете переименовывать. Только владельцы (owners) могут переименовывать проекты.'
        )

        command.send(:show_projects_selection)
      end
    end
  end

  describe '#can_rename_project?' do
    context 'when user is owner' do
      it 'returns true' do
        result = command.send(:can_rename_project?, user, project)
        expect(result).to be true
      end
    end

    context 'when user is not owner' do
      let(:viewer_membership) { create(:membership, user: user, project: project, role: :viewer) }

      before do
        membership.destroy
        viewer_membership
      end

      it 'returns false' do
        result = command.send(:can_rename_project?, user, project)
        expect(result).to be false
      end
    end

    context 'when user has no membership' do
      before do
        membership.destroy
      end

      it 'returns false' do
        result = command.send(:can_rename_project?, user, project)
        expect(result).to be false
      end
    end
  end
end