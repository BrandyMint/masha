# -*- coding: utf-8 -*-
# configures your navigation
#
# ListBootstrap - https://gist.github.com/gmjorge/2572869

SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |primary|
    if logged_in?

      # if current_user.is_root?
      #   primary.item :admin, 'Админство' do |admin|
      #     admin.item :projects, 'Проекты', admin_projects_url, :highlights_on => %r(/admin/projects)
      #     admin.item :users, 'Люди', admin_users_url, :highlights_on => %r(/admin/users)
      #   end
      # end

      primary.item :new_time, menu_new_time, new_time_shift_url
      primary.item :times, menu_times, menu_time_shifts_url

      primary.item :profile, menu_current_user do |user|
        # user.item :available_projects, 'Доступные проект', projects_url, :highlights_on => %r(/projects)
        user.item :edit_profile, 'Профиль', edit_profile_url
        user.item :projects, 'Проекты', projects_url
        user.item :admin, 'Админ', admin_root_url, link: { role: 'no-wiselinks' } if current_user.is_root?
        user.item :logout, 'Выйти', logout_url, link: { role: 'no-wiselinks' }
      end
    else
      primary.item :login, 'Вход', '/login'
      # primary.item :signup, 'Регистрация', '/signup'
      primary.item :developer, 'developer', '/auth/developer' if Rails.env.development?
    end

    primary.dom_class = 'nav navbar-nav pull-right'

    # you can turn off auto highlighting for a specific level
    primary.auto_highlight = true
  end
end
