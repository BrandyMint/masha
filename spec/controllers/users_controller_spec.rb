# frozen_string_literal: true

require 'spec_helper'

describe UsersController, type: :controller do
  let!(:user_attrs) { attributes_for :user }

  describe '#new' do
    it 'should be success' do
      get :new
      expect(response).to be_successful
    end
  end

  describe '#create' do
    context 'with valid params' do
      skip 'should redirect to root_url' do
        post :create,
             params: { register_form: { name: user_attrs[:name], email: user_attrs[:email],
                                        password: user_attrs[:password] } }
        # Invite.sent_to(User.where(email: user_attrs[:email]).first).should be_blank
        expect(response).to redirect_to time_shifts_url
      end
    end

    context 'with invalid params' do
      it 'should render users/new' do
        post :create, params: { register_form: {} }
        expect(response).to render_template('users/new')
      end
    end
  end
end
