class EyePasswordInput < SimpleForm::Inputs::Base
  enable :placeholder, :maxlength

  def input
    input_html_options[:class] << ' j-password-input '
    template.content_tag :div, class: 'input-append user-select-none' do
      @builder.password_field(attribute_name, input_html_options) +
        template.content_tag(:span, template.icon('eye-close'), class: 'add-on', role: 'j-password-toggle')
    end
  end
end
