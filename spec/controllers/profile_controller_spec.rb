# frozen_string_literal: true

require 'spec_helper'

describe ProfileController, type: :controller do
  context 'when not logged in' do
    it 'all actions should return 401' do
      actions = %i[edit update]

      actions.each do |action|
        get action, params: { id: 1 }
        response.code.should == '401'
      end
    end
  end

  context 'when logged in' do
    let!(:user_new_attrs) do
      { user: { email: 'asdf@asdf.ru' } }
    end

    before do
      @user = create :user
      login_user
    end

    describe '#edit' do
      it 'should return success' do
        get :edit
        response.should be_success
      end
    end

    describe '#update' do
      context 'with valid params' do
        it 'should update profile' do
          post :update, params: user_new_attrs
          controller.current_user.email.should == user_new_attrs[:user][:email]
        end
      end

      context 'with invalid params' do
        it 'render ' do
          post :update, params: { user: { email: 'asdf' } }
          response.should render_template('edit')
        end
      end
    end

    describe '#change_password' do
      context 'with valid params' do
        it 'should change password' do
          user = controller.current_user
          old_password = user.crypted_password
          post :change_password, params: { password_change_form: { password: '1234', password_confirmation: '1234' } }
          user.reload
          user.crypted_password.should_not == old_password
        end
      end

      context 'with invalid params' do
        it 'render view' do
          post :change_password, params: { password_change_form: { password: '1234', password_confirmation: '123' } }
          response.should render_template('edit')
        end
      end
    end
  end
end
