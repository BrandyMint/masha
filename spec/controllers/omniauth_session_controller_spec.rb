# frozen_string_literal: true

require 'spec_helper'

describe OmniauthSessionController, type: :controller do
  let(:authentication) { build :authentication }
  let(:user) { authentication.user }
  let!(:auth_attrs) { attributes_for :authentication }

  before do
    controller.request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:default].to_hash
  end

  describe '#create' do
    context 'with valid params' do
      before do
        project = create :project
        create :membership, user: user, project: project
      end
      it 'should log in and redirect to projects_url' do
        post :create

        response.should redirect_to(projects_url)
        controller.current_user.should be_an_instance_of(User)
      end
    end

    context 'with invalid params' do
      it 'should not log in' do
        controller.request.env['omniauth.auth'] = {}
        post :create

        controller.current_user.should_not be_an_instance_of(User)
      end
    end
  end
end
