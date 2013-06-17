SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |primary|
    #if logged_in? && current_user.is_root?
      primary.item :admin, 'admin', admin_root_url
    #end

    primary.dom_class = 'nav pull-left'

    # you can turn off auto highlighting for a specific level
    primary.auto_highlight = true
  end
end

