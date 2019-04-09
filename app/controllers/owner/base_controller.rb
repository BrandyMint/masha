class Owner::BaseController < ApplicationController
  before_action :require_login

  before_action do
    @namespace = :admin
  end
end
