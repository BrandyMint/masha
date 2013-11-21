module MenuHelper

  def menu_projects
    content_tag(:span, ficon('briefcase'), class: 'navbar-menu-icon') +
     content_tag(:span, 'Проекты', class: 'navbar-menu-label')
  end

  def menu_current_user
    content_tag(:span, ficon('user-1'), class: 'navbar-menu-icon')
      # content_tag(:span, 'Профиль', class: 'navbar-menu-label')
  end

  def menu_times
    content_tag(:span, ficon('table'), class: 'navbar-menu-icon') +
      content_tag(:span, 'Получить отчёт', class: 'navbar-menu-label')
  end

  def menu_new_time
    content_tag(:span, ficon('clock-1'), class: ' navbar-menu-icon') +
      content_tag(:span, content_tag(:span, 'Отметить время'), class: 'navbar-menu-label')
  end


end
