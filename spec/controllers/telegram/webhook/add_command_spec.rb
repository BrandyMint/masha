# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  describe '#add!' do
    include_context 'private chat'
    include_context 'authenticated user'

    let!(:project) { create(:project) }
    let!(:membership) { create(:membership, user: user, project: project, role_cd: 0) } # owner role

    before do
      allow(controller).to receive(:find_project).with(project.slug).and_return(project)
    end

    context 'with valid project and hours but without description' do
      subject { -> { dispatch_command :add, project.slug, '2.5' } }

      it { should respond_with_message(/Отметили в #{project.name} 2.5 часов/) }

      it 'creates time shift with empty description' do
        expect { dispatch_command :add, project.slug, '2.5' }.to change(TimeShift, :count).by(1)
        expect(TimeShift.last.description).to eq('')
        expect(TimeShift.last.hours).to eq(2.5)
      end
    end

    context 'with valid project, hours and description' do
      subject { -> { dispatch_command :add, project.slug, '3', 'работал', 'над', 'задачей' } }

      it { should respond_with_message(/Отметили в #{project.name} 3 часов/) }

      it 'creates time shift with joined description' do
        expect { dispatch_command :add, project.slug, '3', 'работал', 'над', 'задачей' }.to change(TimeShift, :count).by(1)
        expect(TimeShift.last.description).to eq('работал над задачей')
        expect(TimeShift.last.hours).to eq(3.0)
      end
    end

    context 'with invalid project' do
      subject { -> { dispatch_command :add, 'nonexistent', '2' } }

      before do
        allow(controller).to receive(:find_project).with('nonexistent').and_return(nil)
      end

      it { should respond_with_message(/Не найден такой проект/) }
    end
  end
end