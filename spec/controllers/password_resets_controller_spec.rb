# frozen_string_literal: true

require 'spec_helper'

describe PasswordResetsController, type: :controller do
  before { ActionMailer::Base.deliveries = [] }
  let(:user) { users(:regular_user) }

  describe '#new' do
    skip 'returns success' do
      get :new
      expect(response).to be_successful
    end
  end

  describe '#create' do
    context 'with valid params' do
      skip 'sends reset password email' do
        post :create, params: { email_form: { email: user.email } }
        expect(response).to redirect_to new_session_path
        expect(ActionMailer::Base.deliveries.last.to.first).to eq(user.email)
      end
    end

    context 'with invalid params' do
      skip 'does not send reset password email' do
        post :create, params: { email_form: { email: 'sdfdsf' } }
        expect(response).to render_template('password_resets/new')
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end
  end

  describe '#edit' do
    let(:user) { users(:regular_user) }
    context 'with valid params' do
      skip 'allows access to set password' do
        get :edit, params: { id: user.reset_password_token }
        expect(response).to be_successful
      end
    end

    context 'with invalid params' do
      skip 'does not allow access to set password' do
        get :edit, params: { id: '32' }
        expect(response).not_to be_successful
      end
    end
  end

  describe '#update' do
    let(:user) { users(:regular_user) }
    context 'with valid params' do
      skip 'changes password' do
        user.crypted_password
        post :update,
             params: { id: '32', token: user.reset_password_token,
                       password_change_form: { password: '1234', password_confirmation: '1234' } }
        user.reload
        expect(user.crypted_password).not_to be_nil
        expect(response).not_to be_successful
      end
    end

    context 'with invalid params' do
      skip 'does not change password' do
        user.crypted_password
        post :update,
             params: { id: '32', token: user.reset_password_token,
                       password_change_form: { password: '1234', password_confirmation: '124' } }
        user.reload
        expect(user.crypted_password).not_to be_nil
        expect(response).to render_template('password_resets/edit')
      end
    end
  end
end
