# frozen_string_literal: true

require 'spec_helper'

describe ProjectsController, type: :controller do
  let!(:project) { projects(:work_project) }
  let!(:project_attrs) do
    {
      slug: 'test-project'
    }
  end

  context 'when not logged in' do
    it 'all actions return 401' do
      actions = %i[index show new create]

      actions.each do |action|
        get action, params: { id: project.id }
        expect(response.code).to eq('401')
      end
    end
  end

  context 'when logged in' do
    before do
      @user = users(:regular_user)
      @request.session[:user_id] = @user.id
    end

    describe '#index' do
      it 'returns success' do
        get :index
        expect(response).to be_successful
      end
    end

    describe '#show' do
      it 'redirects to new_time_shift_url' do
        get :show, params: { id: project.id }
        expect(response).to redirect_to new_time_shift_url(time_shift: { project_id: project.id })
      end
    end

    describe '#new' do
      it 'returns success' do
        get :new
        expect(response).to be_successful
      end
    end

    describe '#create' do
      context 'with valid params' do
        it 'creates project' do
          post :create, params: { project: project_attrs }
          expect(Project.where(project_attrs).first).to be_an_instance_of(Project)
        end
      end

      context 'with invalid params' do
        it 'renders new' do
          post :create, params: { project: { slug: '' } }
          expect(response).to render_template(:new)
        end
      end
    end
  end
end
