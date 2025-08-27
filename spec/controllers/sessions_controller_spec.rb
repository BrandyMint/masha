# frozen_string_literal: true

require 'spec_helper'

describe SessionsController, type: :controller do
  before do
    @user = create :user, password: 123
  end

  describe '#new' do
    it 'should return success' do
      get :new
      response.should be_successful
    end
  end

  describe '#create' do
    context 'with valid params' do
      it 'should log in' do
        get :create, params: { session_form: { email: @user.email, password: 123 } }
        controller.current_user.should be_an_instance_of(User)
      end
    end

    context 'with invalid params' do
      it 'should not log in' do
        get :create, params: { session_form: { email: 'a' } }
        controller.current_user.should_not be_an_instance_of(User)
      end
    end
  end

  describe '#destroy' do
    it 'should log out' do
      login_user
      get :destroy
      controller.current_user.should_not be_an_instance_of(User)
    end
  end
end
