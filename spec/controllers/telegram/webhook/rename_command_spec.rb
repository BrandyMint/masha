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

    context 'when user has no manageable projects' do
      before do
        membership.destroy
      end

      subject { -> { dispatch_command :rename } }
      it { should respond_with_message(/У вас нет проектов, которые вы можете переименовывать/) }
    end
  end
end
