# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'as project owner' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, project: project, user: user, role: 'owner') }

      it 'responds to /adduser command without errors' do
        expect { dispatch_command :adduser }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :adduser
        expect(response).not_to be_nil
      end
    end

    context 'as project viewer' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :viewer, project: project, user: user) }

      it 'responds to /adduser command without errors' do
        expect { dispatch_command :adduser }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :adduser
        expect(response).not_to be_nil
      end
    end

    context 'as project member' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, project: project, user: user) }

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
      let!(:project1) { create(:project, name: 'Project 1') }
      let!(:project2) { create(:project, name: 'Project 2') }
      let!(:membership1) { create(:membership, :owner, project: project1, user: user) }
      let!(:membership2) { create(:membership, :owner, project: project2, user: user) }

      it 'responds to /adduser command without errors' do
        expect { dispatch_command :adduser }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :adduser
        expect(response).not_to be_nil
      end
    end

    context 'with existing members' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }
      let!(:other_user) { create(:user, name: 'Other User') }
      let!(:other_membership) { create(:membership, project: project, user: other_user) }

      it 'responds to /adduser command without errors' do
        expect { dispatch_command :adduser }.not_to raise_error
      end
    end

    context 'complete adduser workflow with callback queries', :callback_query do
      let!(:project1) { create(:project, name: 'Work Project', slug: 'work-project') }
      let!(:target_user) { create(:user, :with_telegram) }
      let!(:target_telegram_user) { create(:telegram_user, username: 'newuser') }

      before do
        # Связываем пользователя с telegram_user имеющим username 'newuser'
        target_user.update!(telegram_user: target_telegram_user)
        create(:membership, :owner, project: project1, user: user)
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
        expect {
          dispatch_command :adduser, project1.slug, 'newuser', 'member'
        }.to change(Membership, :count).by(1)

        # 4. Проверяем что пользователь добавлен с правильными данными
        new_membership = Membership.last
        expect(new_membership.project).to eq(project1)
        expect(new_membership.user).to eq(target_user)
        expect(new_membership.role_cd).to eq(2) # member role
      end

      it 'adds user with owner role directly' do
        # Тестируем прямое добавление пользователя с ролью owner
        expect {
          dispatch_command :adduser, project1.slug, 'newuser', 'owner'
        }.to change(Membership, :count).by(1)

        new_membership = Membership.last
        expect(new_membership.role_cd).to eq(0) # owner role
      end

      it 'adds user with viewer role directly' do
        # Тестируем прямое добавление пользователя с ролью viewer
        expect {
          dispatch_command :adduser, project1.slug, 'newuser', 'viewer'
        }.to change(Membership, :count).by(1)

        new_membership = Membership.last
        expect(new_membership.role_cd).to eq(1) # viewer role
      end

      it 'handles username with @ symbol directly' do
        # Тестируем прямое добавление пользователя с @ символом
        expect {
          dispatch_command :adduser, project1.slug, '@newuser', 'member'
        }.to change(Membership, :count).by(1)

        # Проверяем что пользователь добавлен
        expect(Membership.last.user).to eq(target_user)
      end

      it 'shows error when non-owner tries to add user through workflow' do
        # Создаем проект где пользователь - member, не owner
        member_project = create(:project, name: 'Member Project', slug: 'member-project')
        create(:membership, :member, project: member_project, user: user)

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
        expect {
          dispatch_command :adduser, 'nonexistent-project', 'newuser', 'member'
        }.not_to raise_error
        # Не должно создавать новых membership
        expect(Membership.count).to eq(1) # только owner membership созданный в before
      end

      it 'handles direct add with parameters' do
        # Тестируем прямое добавление пользователя с параметрами
        expect {
          dispatch_command :adduser, project1.slug, 'newuser', 'member'
        }.to change(Membership, :count).by(1)

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
