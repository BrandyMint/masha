class Admin::BaseController < ApplicationController
  before_filter :require_login

  before_filter do
    @namespace = :admin
  end

end
