class DatePickerInput < SimpleForm::Inputs::StringInput
  disable :label
  enable :placeholder

  def input_type
    :date
  end

  protected

  def date_picker_options(value = nil)
    {:value => value, :class => css_class}
  end

  def value
    value ? I18n.l(value) : ''
  end

  def css_class
    "ui-date-picker"
  end
end
