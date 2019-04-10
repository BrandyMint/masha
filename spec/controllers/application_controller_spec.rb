require 'spec_helper'

describe ApplicationController, type: :controller do
  controller do
    def index
      fail ApplicationController::NotLogged
    end
  end

  it 'should return 401 if NotLogged raised' do
    get :index
    response.code.should == '401'
  end
end
