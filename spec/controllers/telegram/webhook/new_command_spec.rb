# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'
  include_context 'private chat'
  include_context 'authenticated user'

  describe '#new!' do
    context 'when slug is provided' do
      subject { -> { dispatch_command :new, 'test_project' } }

      it 'creates a new project with given slug' do
        expect { subject.call }.to change { user.projects.count }.by(1)

        project = user.projects.last
        expect(project.slug).to eq('test_project')
        expect(project.name).to eq('test_project')
      end

      it { should respond_with_message(/Создан проект `test_project`/) }
    end

    context 'when slug is not provided' do
      subject { -> { dispatch_command :new } }

      it 'requests slug from user' do
        expect { subject.call }.not_to(change { user.projects.count })
      end

      it { should respond_with_message(/Укажите slug \(идентификатор\) для нового проекта:/) }
    end
  end

  describe '#new_project_slug_input' do
    # Skip the context setup for now, but test the method directly
    context 'when valid slug is provided' do
      it 'creates a new project' do
        expect { controller.new_project_slug_input('my_project') }.to change { user.projects.count }.by(1)

        project = user.projects.last
        expect(project.slug).to eq('my_project')
        expect(project.name).to eq('my_project')
      end
    end

    context 'when empty slug is provided' do
      it 'does not create project' do
        expect { controller.new_project_slug_input('') }.not_to(change { user.projects.count })
      end
    end

    context 'when whitespace-only slug is provided' do
      it 'does not create project' do
        expect { controller.new_project_slug_input('   ') }.not_to(change { user.projects.count })
      end
    end
  end
end
