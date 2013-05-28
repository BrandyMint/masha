# -*- coding: utf-8 -*-
# configures your navigation

SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |primary|
    if current_user.present?
      primary.item :user, current_user.to_s, user_url(current_user)
      primary.item :signout, 'выйти', signout_url, :method => :destroy
    else
      primary.item :developer, 'developer', '/auth/developer'
      primary.item :github, 'github', '/auth/github'
    end

    primary.dom_class = 'nav pull-right'

    # you can turn off auto highlighting for a specific level
    primary.auto_highlight = true
  end
end
