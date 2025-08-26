# frozen_string_literal: true

require 'spec_helper'

describe ApplicationController, type: :controller do
  controller do
    def index
      raise ApplicationController::NotLogged
    end
  end

  it 'should return 401 if NotLogged raised' do
    get :index
    response.code.should == '401'
  end
end
