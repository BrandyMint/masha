# -*- coding: utf-8 -*-
# configures your navigation
#
# ListBootstrap - https://gist.github.com/gmjorge/2572869

SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |primary|
    if current_user.present?
      primary.item :times, 'Время', time_shifts_url
      primary.item :projects, 'Проекты', projects_url, :highlights_on => %r(/projects)
      primary.item :users, 'Люди', users_url, :highlights_on => %r(/users) if current_user.has_role? :admin
      primary.item :user, current_user.to_s, user_url(current_user)
      primary.item :signout, 'выйти', signout_url, :icon => 'icon-off', :method => :destroy
    else
      primary.item :developer, 'developer', '/auth/developer'
      primary.item :github, 'github', '/auth/github'
    end

    primary.dom_class = 'nav pull-right'

    # you can turn off auto highlighting for a specific level
    primary.auto_highlight = true
  end
end
