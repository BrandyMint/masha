# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  describe '#rename!' do
    include_context 'private chat'
    include_context 'authenticated user'

    let!(:project) { create(:project, name: 'Old Project', slug: 'old-project') }
    let!(:membership) { create(:membership, user: user, project: project, role_cd: 0) } # owner role

    context 'without parameters' do
      subject { -> { dispatch_command :rename } }
      it { should respond_with_message(/Выберите проект для переименования/) }
    end

    context 'with valid parameters' do
      subject { -> { dispatch_command :rename, 'old-project', 'New', 'Project' } }
      it { should respond_with_message(/✅ Проект успешно переименован/) }
      it { change { project.reload.name }.from('Old Project').to('New Project') }
    end

    context 'with project that does not exist' do
      subject { -> { dispatch_command :rename, 'nonexistent-project', 'New Project' } }
      it { should respond_with_message(/Проект с slug 'nonexistent-project' не найден/) }
    end

    context 'when user is not owner' do
      before do
        membership.update!(role_cd: 2) # member role
      end

      subject { -> { dispatch_command :rename, 'old-project', 'New Project' } }
      it { should respond_with_message(/У вас нет прав для переименования этого проекта/) }
    end

    context 'with too short name' do
      subject { -> { dispatch_command :rename, 'old-project', 'A' } }
      it { should respond_with_message(/Название проекта должно содержать минимум 2 символа/) }
    end

    context 'with duplicate project name' do
      let!(:other_project) { create(:project, name: 'Existing Project', slug: 'existing-project') }

      subject { -> { dispatch_command :rename, 'old-project', 'Existing Project' } }
      it { should respond_with_message(/Проект с таким названием уже существует/) }
    end

    context 'callback query handling' do
      let(:callback_data) { 'rename_project:old-project' }

      it 'handles project selection callback' do
        expect { dispatch_callback :callback_query, callback_data }
          .to respond_with_message(/Проект: Old Project/)
          .and change { session[:telegram_session] }.from(nil)
      end
    end

    context 'when user has no manageable projects' do
      before do
        membership.destroy
      end

      subject { -> { dispatch_command :rename } }
      it { should respond_with_message(/У вас нет проектов, которые вы можете переименовывать/) }
    end
  end

  describe 'rename callback flow' do
    include_context 'private chat'
    include_context 'authenticated user'

    let!(:project) { create(:project, name: 'Test Project', slug: 'test-project') }
    let!(:membership) { create(:membership, user: user, project: project, role_cd: 0) }

    context 'full rename workflow' do
      it 'handles complete rename process through callbacks' do
        # Step 1: Start rename command
        dispatch_command :rename
        expect(response[:text]).to match(/Выберите проект для переименования/)

        # Step 2: Select project
        dispatch_callback :callback_query, 'rename_project:test-project'
        expect(response[:text]).to match(/Проект: Test Project/)
        expect(response[:text]).to match(/Введите новое название/)

        # Step 3: Input new name
        dispatch_message 'New Awesome Project'
        expect(response[:text]).to match(/Подтвердите переименование проекта/)
        expect(response[:text]).to match(/Текущее название: Test Project/)
        expect(response[:text]).to match(/Новое название: New Awesome Project/)

        # Step 4: Confirm rename
        dispatch_callback :callback_query, 'rename_confirm:save'
        expect(response[:text]).to match(/✅ Проект успешно переименован/)
        expect(project.reload.name).to eq('New Awesome Project')
      end

      it 'handles cancel during confirmation' do
        # Start the workflow
        dispatch_command :rename
        dispatch_callback :callback_query, 'rename_project:test-project'
        dispatch_message 'New Awesome Project'

        # Cancel the operation
        dispatch_callback :callback_query, 'rename_confirm:cancel'
        expect(response[:text]).to match(/Переименование отменено/)
        expect(project.reload.name).to eq('Test Project')
      end
    end
  end
end