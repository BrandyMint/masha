# frozen_string_literal: true

require 'spec_helper'

describe ProfileController, type: :controller do
  context 'when not logged in' do
    it 'all actions return 401' do
      actions = %i[edit update]

      actions.each do |action|
        get action, params: { id: 1 }
        expect(response.code).to eq('401')
      end
    end
  end

  context 'when logged in' do
    let!(:user_new_attrs) do
      { user: { email: 'asdf@asdf.ru' } }
    end

    before do
      @user = users(:regular_user)
      login_user @user
    end

    describe '#edit' do
      it 'returns success' do
        get :edit
        expect(response).to be_successful
      end
    end

    describe '#update' do
      context 'with valid params' do
        it 'updates profile' do
          post :update, params: user_new_attrs
          expect(controller.current_user.email).to eq(user_new_attrs[:user][:email])
        end
      end

      context 'with invalid params' do
        it 'render ' do
          post :update, params: { user: { email: 'asdf' } }
          expect(response).to render_template('edit')
        end
      end
    end

    describe '#change_password' do
      context 'with valid params' do
        it 'changes password' do
          user = controller.current_user
          old_password = user.crypted_password
          post :change_password, params: { password_change_form: { password: '1234', password_confirmation: '1234' } }
          user.reload
          expect(user.crypted_password).not_to eq(old_password)
        end
      end

      context 'with invalid params' do
        it 'render view' do
          post :change_password, params: { password_change_form: { password: '1234', password_confirmation: '123' } }
          expect(response).to render_template('edit')
        end
      end
    end
  end
end
