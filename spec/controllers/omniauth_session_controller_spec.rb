# frozen_string_literal: true

require 'spec_helper'

describe OmniauthSessionController, type: :controller do
  let(:user) { users(:telegram_clean_user) }
  before do
    # Настраиваем мок для GitHub OAuth
    OmniAuth.config.mock_auth[:github] = {
      'provider' => 'github',
      'uid' => '999999', # Используем другой UID чтобы избежать конфликта с существующей аутентификацией
      'info' => {
        'nickname' => user.nickname,
        'email' => user.email,
        'name' => user.name
      },
      'credentials' => {
        'token' => 'mock_token',
        'secret' => 'mock_secret'
      }
    }

    # Устанавливаем мок для OAuth
    controller.request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
  end

  describe '#create' do
    context 'with valid GitHub OAuth' do
      before do
        # Используем существующие fixtures для проекта и членства
        @project = projects(:work_project)
        @membership = memberships(:clean_user_work_owner)
      end

      it 'logs in via GitHub and redirects to appropriate page' do
        post :create, params: { provider: 'github' }

        # Проверяем, что пользователь залогинен
        expect(controller.current_user).to eq(user)
        expect(session[:user_id].to_i).to eq(user.id)

        # Проверяем, что происходит редирект (конкретный URL зависит от роли пользователя)
        expect(response).to be_redirect
      end

      it 'creates authentication record if it does not exist' do
        expect do
          post :create, params: { provider: 'github' }
        end.to change(Authentication, :count).by(1)

        auth = Authentication.last
        expect(auth.provider).to eq('github')
        expect(auth.uid).to eq('999999') # Ожидаем новый UID
        expect(auth.user).to eq(user)
      end
    end

    context 'with invalid OAuth data' do
      before do
        controller.request.env['omniauth.auth'] = {}
      end

      it 'does not log in with empty auth data' do
        controller.request.env['omniauth.auth'] = {}
        post :create, params: { provider: 'github' }

        expect(response).to redirect_to(root_url)
      end
    end
  end
end
