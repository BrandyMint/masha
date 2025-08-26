# frozen_string_literal: true

require 'spec_helper'

describe OmniauthSessionController, type: :controller do
  let!(:auth_attrs) { attributes_for :authentication }

  describe '#create' do
    context 'with valid params' do
      it 'should log in and redirect to projects_url' do
        controller.request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:default]
        post :create, params: auth_attrs

        response.should redirect_to(projects_url)
        controller.current_user.should be_an_instance_of(User)
      end
    end

    context 'with invalid params' do
      it 'should not log in' do
        controller.request.env['omniauth.auth'] = {}
        post :create, params: auth_attrs

        controller.current_user.should_not be_an_instance_of(User)
      end
    end
  end
end
