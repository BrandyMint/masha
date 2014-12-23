require 'spec_helper'

describe WelcomeController do
  describe '#index' do
    context 'when logged in' do
      before do
        @user = create :user
        login_user
      end

      it 'should redirect to time_shifts' do
        get :index
        response.should redirect_to time_shifts_url
      end
    end

    context 'when not logged in' do
      it 'should be success' do
        get :index
        response.should be_success
      end
    end
  end
end
