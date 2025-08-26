# frozen_string_literal: true

class AuthenticationDecorator < ApplicationDecorator
  delegate_all

  def nickname
    h.link_to object.nickname, object.html_url, { target: object.html_url.present? ? '_blank' : '_self' }
  end
end
