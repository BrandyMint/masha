class DatePickerInput < SimpleForm::Inputs::StringInput
  enable :placeholder

  def input
    # Если мы будем ограничивать, то пропадает возможность смотреть "весь месяц"
    #input_html_options[:max] = Date.today.end_of_week
    
    value = object.send(attribute_name) if object.respond_to? attribute_name
    #display_pattern = I18n.t('datepicker.dformat', :default => '%d-%m-%Y')
    display_pattern = I18n.t('datepicker.dformat', :default => '%Y-%m-%d')
    input_html_options[:value] ||= I18n.localize((value.is_a?(String) ? Date.parse(value) : value), :format => display_pattern) if value.present?
    #input_html_options[:placeholder] ||= 'dd-mm-yyyy'
    input_html_options[:placeholder] ||= 'yyyy-mm-dd'

    input_html_options[:type] = 'text'
    #picker_pettern = I18n.t('datepicker.pformat', :default => 'dd-MM-yyyy') 
    picker_pettern = I18n.t('datepicker.pformat', :default => 'yyyy-MM-dd') 
    
    input_html_options[:data] ||= {}
    input_html_options[:data].merge!({ format: picker_pettern, language: I18n.locale.to_s,
                                       date_weekstart: I18n.t('datepicker.weekstart', :default => 0, start_date: Date.today) })
    
    arbre attribute_name: attribute_name, input_html_options: input_html_options, builder: @builder, shortcuts: shortcuts do
      div class: 'input-group datepicker-group', role: "date-picker" do
        span do
          builder.text_field attribute_name, input_html_options
        end
        span class: 'input-group-addon add-on' do
          i class: 'fontello-icon-calendar'
        end
      end
      div do
        "#{shortcuts}".html_safe
      end
    end

  end

  def input_type
    :date
  end

  protected

  def shortcuts
    date = object.send( attribute_name )
    date = Date.today if date.blank?
    date = Date.parse date if date.is_a? String

    case attribute_name
    when :date
      arbre :today => t(:today), :yesterday => t(:yesterday) do
        ul :class => 'date-shortcuts' do
          li helpers.link_to( yesterday, '#', :role => 'date-shortcut', :data => {:value => Date.yesterday.to_s } )
          li helpers.link_to( today,     '#', :role => 'date-shortcut', :data => {:value => Date.today.to_s } )
        end
      end
    when :date_from
    when :date_to
      arbre :date => date do
        ul :class => 'date-shortcuts' do
          #months
          [date.prev_month, date].each do |m|
            month_name = I18n.l m, :format => '%B'
            li helpers.link_to(
              month_name,
              '#',
              :role => 'period-shortcut',
              :data => { :date_from => m.beginning_of_month.to_s, :date_to => m.end_of_month.to_s }
            )
          end

          #weeks
          [date.prev_week, date].each do |m|
            this = m.end_of_week >= Date.today ? '(текущая)' : ''
            week_name = "Неделя##{m.strftime '%U'}#{this}"
            li helpers.link_to(
              week_name,
              '#',
              :role => 'period-shortcut',
              :data => { :date_from => m.beginning_of_week.to_s, :date_to => m.end_of_week.to_s }
            )
          end

        end
      end
    end
  end

  def t key
    I18n.t key, :scope => [:simple_form, :shortcuts]
  end
end
