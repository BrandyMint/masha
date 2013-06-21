class DatePickerInput < SimpleForm::Inputs::StringInput
  enable :placeholder
  enable :shortcuts

  def input
    super << shortcuts
  end

  def input_type
    :date
  end

  protected

  def shortcuts
    arbre( {:today => t(:today), :yesterday => t(:yesterday) } ) do
      ul :class => 'input-shortcuts horizontal-list' do
        li helpers.link_to( yesterday, '#', :class => 'date-shortcut', :data => {:value => Date.yesterday.to_s } )
        li helpers.link_to( today, '#', :class => 'date-shortcut', :data => {:value => Date.today.to_s } )
      end
    end
  end

  def t key
    I18n.t key, :scope => [:simple_form, :shortcuts]
  end

  def date_picker_options value = nil
    {:value => value, :class => css_class}
  end

  def css_class
    "ui-date-picker"
  end
end
