module IconHelper

  def ficon icon, args={}
    fontello icon, args
  end

  def fontello icon, args={}
    return unless args.is_a? Hash
    args.each_pair do |key, value|
      args[key] ||= ''
    end
    args.merge! class: "fontello-icon-#{icon} icon-size-#{args[:size]} icon-color-#{args[:color]} 
      v-align-#{args[:v_align]} #{args[:custom_class]}"
    content_tag :i, '', args
  end

  def icon *classes
    css = classes.map{|c| "icon-#{c}"}.join(' ')
    content_tag :i, '', :class => "icon #{css}"
  end

  def tooltiped_icon icon, tooltip_title
    content_tag :span, :rel => :tooltip, :title => tooltip_title do
      fontello icon
    end
  end

end
