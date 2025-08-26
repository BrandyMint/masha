# frozen_string_literal: true

module Owner
  class BaseController < ApplicationController
    before_action :require_login

    before_action do
      @namespace = :admin
    end
  end
end
