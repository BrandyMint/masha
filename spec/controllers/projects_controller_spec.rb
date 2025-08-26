# frozen_string_literal: true

require 'spec_helper'

describe ProjectsController, type: :controller do
  let!(:project) { create :project }
  let!(:project_attrs) { attributes_for :project }

  context 'when not logged in' do
    it 'all actions should return 401' do
      actions = %i[index show new create]

      actions.each do |action|
        get action, params: { id: project.id }
        response.code.should == '401'
      end
    end
  end

  context 'when logged in' do
    before do
      @user = create :user
      login_user
    end

    describe '#index' do
      it 'should return success' do
        get :index
        response.should be_success
      end
    end

    describe '#show' do
      it 'should redirect to new_time_shift_url' do
        get :show, params: { id: project.id }
        response.should redirect_to new_time_shift_url(time_shift: { project_id: project.id })
      end
    end

    describe '#new' do
      it 'should return success' do
        get :index
        response.should be_success
      end
    end

    describe '#create' do
      context 'with valid params' do
        it 'should create project' do
          post :create, params: { project: project_attrs }
          Project.where(project_attrs).first.should be_an_instance_of(Project)
        end
      end

      context 'with invalid params' do
        it 'should render new' do
          post :new, params: { project: {} }
          response.should render_template :new
        end
      end
    end
  end
end
