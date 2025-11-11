# frozen_string_literal: true

require 'spec_helper'

describe TimeShiftsController, type: :controller do
  let!(:time_shift_attrs) do
    {
      hours: 2.5,
      description: 'Test work',
      date: Date.current
    }
  end
  let!(:project) { projects(:work_project) }

  context 'when not logged in' do
    it 'all actions return 401' do
      actions = %i[index show new create edit destroy]

      actions.each do |action|
        get action, params: { id: 1 }
        expect(response.code).to eq('401')
      end
    end
  end

  context 'when logged in' do
    before do
      @user = users(:regular_user)
      @time_shift = time_shifts(:work_time_today)
      @request.session[:user_id] = @user.id
    end

    describe '#index' do
      it 'is successful' do
        get :index
        expect(response).to be_successful
      end
    end

    describe '#show' do
      it 'redirects to time_shifts_url' do
        get :show, params: { id: @time_shift.id }
        expect(response).to redirect_to time_shifts_url
      end
    end

    describe '#new' do
      it 'is successful' do
        get :new
        expect(response).to be_successful
      end
    end

    describe '#create' do
      context 'with valid params' do
        it 'redirects to new_time_shift_url' do
          time_shift_attrs.merge!(project_id: project.id)
          post :create, params: { time_shift: time_shift_attrs }
          expect(TimeShift.where(time_shift_attrs).first).to be_an_instance_of(TimeShift)
          expect(response).to redirect_to new_time_shift_url
        end
      end

      context 'with invalid params' do
        it 'is successful' do
          post :create, params: { time_shift: {} }
          expect(response).to be_successful
        end
      end
    end

    describe '#edit' do
      it 'renders edit' do
        get :edit, params: { id: @time_shift.id }
        expect(response).to render_template('edit')
      end
    end

    describe '#destroy' do
      it 'redirects to time_shifts_url' do
        delete :destroy, params: { id: @time_shift.id }
        expect(TimeShift.where(id: @time_shift.id).first).to be_nil
        expect(response).to redirect_to time_shifts_url
      end
    end
  end
end
