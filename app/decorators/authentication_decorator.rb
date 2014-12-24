class AuthenticationDecorator < ApplicationDecorator
  delegate_all

  def nickname
    h.link_to source.nickname, source.url
  end
end
