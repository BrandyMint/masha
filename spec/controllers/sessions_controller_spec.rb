# frozen_string_literal: true

require 'spec_helper'

describe SessionsController, type: :controller do
  # Используем fixtures вместо создания пользователей
  let(:user) { users(:regular_user) }

  describe '#new' do
    it 'returns success response' do
      get :new
      expect(response).to be_successful
    end
  end

  describe '#create' do
    context 'with valid params' do
      it 'logs in user' do
        post :create, params: { session_form: { email: user.email, password: '123' } }

        expect(response).to redirect_to(time_shifts_url)
        expect(controller.current_user).to eq(user)
        expect(session[:user_id].to_i).to eq(user.id)
      end
    end

    context 'with invalid params' do
      it 'does not log in with wrong email' do
        post :create, params: { session_form: { email: 'wrong@example.com', password: '123' } }

        expect(response).to render_template(:new)
        expect(controller.current_user).to be_nil
        expect(session[:user_id]).to be_nil
      end

      it 'does not log in with wrong password' do
        post :create, params: { session_form: { email: user.email, password: 'wrong' } }

        expect(response).to render_template(:new)
        expect(controller.current_user).to be_nil
        expect(session[:user_id]).to be_nil
      end
    end
  end

  describe '#destroy' do
    it 'logs out user' do
      # Устанавливаем пользователя в сессию
      session[:user_id] = user.id.to_s

      get :destroy

      expect(response).to redirect_to(root_url)
      expect(controller.current_user).to be_nil
      expect(session[:user_id]).to be_nil
    end
  end
end
