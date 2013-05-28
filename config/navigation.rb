# -*- coding: utf-8 -*-
# configures your navigation

SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |primary|
    # primary.item :hotels, I18n.t("admin.menu.hotels"), hotels_url

    primary.dom_class = 'nav pull-right'

    # you can turn off auto highlighting for a specific level
    primary.auto_highlight = true
  end
end
