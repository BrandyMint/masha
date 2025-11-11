# frozen_string_literal: true

require 'spec_helper'

describe WelcomeController, type: :controller do
  describe '#index' do
    context 'when logged in' do
      let(:user) { users(:regular_user) }

      before do
        login_user user
      end

      it 'redirects to time_shifts' do
        get :index
        expect(response).to redirect_to new_time_shift_url
      end
    end

    context 'when not logged in' do
      it 'is successful' do
        get :index
        expect(response).to be_successful
      end
    end
  end
end
