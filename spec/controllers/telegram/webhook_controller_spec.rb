# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  # for old RSpec:
  # include_context 'telegram/bot/integration/rails'

  # Main method is #dispatch(update). Some helpers are:
  #   dispatch_message(text, options = {})
  #   dispatch_command(cmd, *args)

  # Available matchers can be found in Telegram::Bot::RSpec::ClientMatchers.
  # it 'shows usage of basic matchers' do
  ## The most basic one is #make_telegram_request(bot, endpoint, params_matcher)
  # expect { dispatch_command(:start) }.
  # to make_telegram_request(bot, :sendMessage, hash_including(text: 'msg text'))

  ## There are some shortcuts for dispatching basic updates and testing responses.
  # expect { dispatch_message('Hi') }.to send_telegram_message(bot, /msg regexp/, some: :option)
  # end

  let!(:user) { create :user }

  context 'private chat' do
    let(:chat_id) { from_id }

    context 'unauthenticated user' do
      describe '#start!' do
        subject { -> { dispatch_command :start } }
        it { should respond_with_message(/перейдите/) }
      end

      describe '#projects!' do
        subject { -> { dispatch_command :projects } }
        it { should respond_with_message(/Привяжи/) }
      end

      describe '#message' do
        subject { -> { dispatch_message 'talk something' } }
        it { should respond_with_message(/конкретика/) }
      end
    end

    context 'logged user' do
      before do
        allow(controller).to receive(:current_user) { user }
      end
      describe '#start!' do
        subject { -> { dispatch_command :start } }
        it { should respond_with_message(/возращением/) }
      end

      describe '#adduser!' do
        context 'without parameters' do
          subject { -> { dispatch_command :adduser } }
          it { should respond_with_message(/Укажите название проекта/) }
        end

        context 'without username' do
          subject { -> { dispatch_command :adduser, 'project1' } }
          it { should respond_with_message(/Укажите никнейм пользователя/) }
        end
      end

      describe '#add!' do
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
  end

  context 'public chat' do
    let(:chat_id) { -from_id }
    describe '#message' do
      subject { -> { dispatch_message 'talk something' } }
      it { should_not respond_with_message }
    end
  end

  ## There is context for callback queries with related matchers,
  ## use :callback_query tag to include it.
  # describe '#hey_callback_query', :callback_query do
  # let(:data) { "hey:#{name}" }
  # let(:name) { 'Joe' }
  # it { should answer_callback_query('Hey Joe') }
  # it { should edit_current_message :text, text: 'Done' }
  # end
end
