# frozen_string_literal: true

require 'spec_helper'

describe UsersController, type: :controller do
  let(:user_attrs) do
    {
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123'
    }
  end

  describe '#new' do
    it 'is successful' do
      get :new
      expect(response).to be_successful
    end
  end

  describe '#create' do
    context 'with valid params' do
      skip 'redirects to root_url - authentication issue' do
        post :create,
             params: { register_form: { name: user_attrs[:name], email: user_attrs[:email],
                                        password: user_attrs[:password] } }
        # expect(Invite.sent_to(User.where(email: user_attrs[:email]).first)).to be_blank
        expect(response).to redirect_to time_shifts_url
      end
    end

    context 'with invalid params' do
      it 'renders users/new' do
        post :create, params: { register_form: {} }
        expect(response).to render_template('users/new')
      end
    end
  end
end
