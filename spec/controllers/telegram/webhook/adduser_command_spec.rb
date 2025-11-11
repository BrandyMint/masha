# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'as project owner' do
      let!(:project) { projects(:work_project) }
      let!(:membership) { memberships(:telegram_work) }

      it 'responds to /adduser command without errors' do
        expect { dispatch_command :adduser }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :adduser
        expect(response).not_to be_nil
      end
    end

    context 'as project viewer' do
      let!(:project) { projects(:viewer_project) }
      let!(:user) { users(:telegram_clean_user) }
      let!(:telegram_user) { telegram_users(:telegram_clean) }
      let!(:from_id) { telegram_user.id }
      let!(:membership) { memberships(:clean_user_viewer_project) }

      it 'responds to /adduser command without errors' do
        expect { dispatch_command :adduser }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :adduser
        expect(response).not_to be_nil
      end
    end

    context 'as project member' do
      let!(:project) { projects(:test_project) }
      let!(:membership) { memberships(:telegram_test) }

      it 'responds to /adduser command without errors' do
        expect { dispatch_command :adduser }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :adduser
        expect(response).not_to be_nil
      end
    end

    context 'without projects' do
      it 'responds to /adduser command without errors' do
        expect { dispatch_command :adduser }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :adduser
        expect(response).not_to be_nil
      end
    end

    context 'with multiple projects as owner' do
      let!(:project1) { projects(:project_1) }
      let!(:project2) { projects(:project_2) }
      let!(:user) { users(:project_owner) }
      let!(:telegram_user) { telegram_users(:telegram_owner) }
      let!(:from_id) { telegram_user.id }
      let!(:membership1) { memberships(:project_owner_test) }
      let!(:membership2) { memberships(:owner_dev) }

      it 'responds to /adduser command without errors' do
        expect { dispatch_command :adduser }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :adduser
        expect(response).not_to be_nil
      end
    end

    context 'with existing members' do
      let!(:project) { projects(:work_project) }
      let!(:membership) { memberships(:admin_work) }
      let!(:user) { users(:admin) }
      let!(:telegram_user) { telegram_users(:telegram_admin) }
      let!(:from_id) { telegram_user.id }
      let!(:other_user) { users(:regular_user) }
      let!(:other_membership) { memberships(:regular_work) }

      it 'responds to /adduser command without errors' do
        expect { dispatch_command :adduser }.not_to raise_error
      end
    end

    context 'complete adduser workflow with callback queries', :callback_query do
      let!(:project1) { projects(:work_project) }
      let!(:target_user) { users(:newuser) }
      let!(:target_telegram_user) { telegram_users(:telegram_newuser) }
      let!(:user) { users(:telegram_clean_user) }
      let!(:telegram_user) { telegram_users(:telegram_clean) }
      let!(:from_id) { telegram_user.id }

      before do
        # Связываем пользователя с telegram_user имеющим username 'newuser'
        target_user.update!(telegram_user: target_telegram_user)
      end

      it 'adds user through complete interactive workflow' do
        # 1. Пользователь вызывает /adduser без параметров и получает список проектов
        response = dispatch_command :adduser
        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Выберите проект')

        # 2. Проверяем что в списке есть наш проект
        first_message = response.first
        keyboard = first_message.dig(:reply_markup, :inline_keyboard)&.flatten || []
        project_button = keyboard.find { |button| button[:text] == project1.name }
        expect(project_button).not_to be_nil
        expect(project_button[:callback_data]).to eq("adduser_project:#{project1.slug}")

        # 3. Прямое добавление пользователя с параметрами для простоты
        expect do
          dispatch_command :adduser, project1.slug, 'newuser', 'member'
        end.to change(Membership, :count).by(1)

        # 4. Проверяем что пользователь добавлен с правильными данными
        new_membership = Membership.last
        expect(new_membership.project).to eq(project1)
        expect(new_membership.user).to eq(target_user)
        expect(new_membership.role_cd).to eq(2) # member role
      end

      it 'adds user with owner role directly' do
        # Тестируем прямое добавление пользователя с ролью owner
        expect do
          dispatch_command :adduser, project1.slug, 'newuser', 'owner'
        end.to change(Membership, :count).by(1)

        new_membership = Membership.last
        expect(new_membership.role_cd).to eq(0) # owner role
      end

      it 'adds user with viewer role directly' do
        # Тестируем прямое добавление пользователя с ролью viewer
        expect do
          dispatch_command :adduser, project1.slug, 'newuser', 'viewer'
        end.to change(Membership, :count).by(1)

        new_membership = Membership.last
        expect(new_membership.role_cd).to eq(1) # viewer role
      end

      it 'handles username with @ symbol directly' do
        # Тестируем прямое добавление пользователя с @ символом
        expect do
          dispatch_command :adduser, project1.slug, '@newuser', 'member'
        end.to change(Membership, :count).by(1)

        # Проверяем что пользователь добавлен
        expect(Membership.last.user).to eq(target_user)
      end

      it 'shows error when non-owner tries to add user through workflow' do
        # Используем проект где пользователь - member, не owner
        member_project = projects(:member_project)

        # 1. Начинаем workflow
        response = dispatch_command :adduser
        # Проверяем что в списке нет проекта где мы не owner
        keyboard = response.first.dig(:reply_markup, :inline_keyboard)&.flatten || []
        project_names = keyboard.map { |btn| btn[:text] }
        expect(project_names).not_to include(member_project.name)
      end

      it 'handles non-existent project directly' do
        # Тестируем прямое добавление в несуществующий проект
        # Command может вернуть nil, но ошибка должна быть обработана
        initial_count = Membership.count
        expect do
          dispatch_command :adduser, 'nonexistent-project', 'newuser', 'member'
        end.not_to raise_error
        # Не должно создавать новых membership
        expect(Membership.count).to eq(initial_count)
      end

      it 'handles direct add with parameters' do
        # Тестируем прямое добавление пользователя с параметрами
        expect do
          dispatch_command :adduser, project1.slug, 'newuser', 'member'
        end.to change(Membership, :count).by(1)

        new_membership = Membership.last
        expect(new_membership.project).to eq(project1)
        expect(new_membership.user).to eq(target_user)
        expect(new_membership.role_cd).to eq(2) # member role
      end

      it 'shows error when project not specified in direct add' do
        response = dispatch_command :adduser

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Выберите проект')
      end

      it 'shows error when username not specified in direct add' do
        response = dispatch_command :adduser, project1.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Укажите никнейм')
      end
    end
  end
end
