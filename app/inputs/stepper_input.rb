class StepperInput < SimpleForm::Inputs::StringInput
  enable :placeholder

  def input
    # input_html_options[:min] = 0
    # input_html_options[:max] = 24

    value = object.send(attribute_name) if object.respond_to? attribute_name

    input_html_options[:type] = 'numeric'
    input_html_options[:autocomplete] = 'off'

    # input_html_options[:data] ||= {}
    # input_html_options[:data].merge!({role })

    arbre attribute_name: attribute_name, input_html_options: input_html_options, builder: @builder do
      div class: 'input-group numeric-stepper', role: 'stepper' do
        span class: 'input-group-addon minus' do
          i class: 'fontello-icon-minus'
        end
        span do
          builder.text_field attribute_name, input_html_options
        end
        span class: 'input-group-addon plus' do
          i class: 'fontello-icon-plus'
        end
      end
    end
  end
end
