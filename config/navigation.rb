# -*- coding: utf-8 -*-
# configures your navigation
#
# ListBootstrap - https://gist.github.com/gmjorge/2572869

SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |primary|
    if logged_in?

      #if current_user.is_root?
        #primary.item :admin, 'Админство' do |admin|
          #admin.item :projects, 'Проекты', admin_projects_url, :highlights_on => %r(/admin/projects)
          #admin.item :users, 'Люди', admin_users_url, :highlights_on => %r(/admin/users)
        #end
      #end

      primary.item :new_time, 'Отметить', new_time_shift_url
      primary.item :times, 'Отчеты', time_shifts_url

      primary.item :profile, current_user.to_s do |user|
        #user.item :available_projects, 'Доступные проект', projects_url, :highlights_on => %r(/projects)
        user.item :edit_profile, 'Профиль', edit_profile_url
        user.item :admin, 'Админ', admin_root_url, 'data-no-turbolink'=>true if current_user.is_root?
        user.item :logout, 'Выйти', logout_url
      end
    else
      primary.item :login, 'Вход', '/login'
      primary.item :signup, 'Регистрация', '/signup'
      primary.item :developer, 'developer', '/auth/developer' if Rails.env.development?
      primary.item :github, 'github', '/auth/github'
    end

    primary.dom_class = 'nav pull-right'

    # you can turn off auto highlighting for a specific level
    primary.auto_highlight = true
  end
end
