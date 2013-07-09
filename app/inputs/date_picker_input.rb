class DatePickerInput < SimpleForm::Inputs::StringInput
  enable :placeholder

  def input
    input_html_options[:max] = Date.today
    super << shortcuts
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
          li helpers.link_to( yesterday, '#', :class => 'date-shortcut', :data => {:value => Date.yesterday.to_s } )
          li helpers.link_to( today, '#', :class => 'date-shortcut', :data => {:value => Date.today.to_s } )
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
              :class => 'period-shortcut',
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
              :class => 'period-shortcut',
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
