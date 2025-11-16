# frozen_string_literal: true

class HelpController < ApplicationController
  skip_before_action :require_login, raise: false

  def index; end

  def guide; end

  def quick_start; end

  def commands; end

  def time_format; end

  def projects; end

  def faq; end
end
