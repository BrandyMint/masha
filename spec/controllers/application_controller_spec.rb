# frozen_string_literal: true

require 'spec_helper'

describe ApplicationController, type: :controller do
  controller do
    def index
      raise NotLogged
    end
  end

  it 'returns 401 if NotLogged raised' do
    get :index
    expect(response.code).to eq('401')
  end
end
