class AuthenticationDecorator < ApplicationDecorator
  delegate_all

  def nickname
    h.link_to source.nickname, source.html_url, html_options = {target: source.html_url.present? ? "_blank" : "_self"}
  end
end
