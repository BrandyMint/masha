# frozen_string_literal: true

# Use this setup block to configure all options available in SimpleForm.
# Updated for Bootstrap 5 compatibility
# Inside your views, use 'simple_form_for' with Bootstrap 5 form classes
SimpleForm.setup do |config|
  # Bootstrap 5 default wrapper
  config.wrappers :bootstrap, tag: 'div', class: 'mb-3', error_class: 'is-invalid' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label, class: 'form-label'
    b.use :input, class: 'form-control', error_class: 'is-invalid', valid_class: 'is-valid'
    b.use :error, wrap_with: { tag: 'div', class: 'invalid-feedback' }
    b.use :hint, wrap_with: { tag: 'div', class: 'form-text' }
  end

  # Bootstrap 5 floating labels wrapper
  config.wrappers :floating, tag: 'div', class: 'form-floating mb-3', error_class: 'is-invalid' do |b|
    b.use :html5
    b.use :placeholder
    b.use :input, class: 'form-control', error_class: 'is-invalid', valid_class: 'is-valid'
    b.use :label, class: 'form-label'
    b.use :error, wrap_with: { tag: 'div', class: 'invalid-feedback' }
    b.use :hint, wrap_with: { tag: 'div', class: 'form-text' }
  end

  # Bootstrap 5 input group wrapper for prepend/append
  config.wrappers :input_group, tag: 'div', class: 'mb-3', error_class: 'is-invalid' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label, class: 'form-label'
    b.wrapper tag: 'div', class: 'input-group' do |input_group|
      input_group.use :input, class: 'form-control', error_class: 'is-invalid', valid_class: 'is-valid'
    end
    b.use :error, wrap_with: { tag: 'div', class: 'invalid-feedback' }
    b.use :hint, wrap_with: { tag: 'div', class: 'form-text' }
  end

  # Bootstrap 5 checkbox wrapper
  config.wrappers :check_boxes, tag: 'div', class: 'mb-3', error_class: 'is-invalid' do |b|
    b.use :html5
    b.wrapper tag: 'div', class: 'form-check' do |ba|
      ba.use :input, class: 'form-check-input', error_class: 'is-invalid', valid_class: 'is-valid'
      ba.use :label, class: 'form-check-label'
    end
    b.use :error, wrap_with: { tag: 'div', class: 'invalid-feedback' }
    b.use :hint, wrap_with: { tag: 'div', class: 'form-text' }
  end

  # Bootstrap 5 radio buttons wrapper
  config.wrappers :radio_buttons, tag: 'div', class: 'mb-3', error_class: 'is-invalid' do |b|
    b.use :html5
    b.wrapper tag: 'div', class: 'form-check' do |ba|
      ba.use :input, class: 'form-check-input', error_class: 'is-invalid', valid_class: 'is-valid'
      ba.use :label, class: 'form-check-label'
    end
    b.use :error, wrap_with: { tag: 'div', class: 'invalid-feedback' }
    b.use :hint, wrap_with: { tag: 'div', class: 'form-text' }
  end

  # Bootstrap 5 select wrapper
  config.wrappers :select, tag: 'div', class: 'mb-3', error_class: 'is-invalid' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label, class: 'form-label'
    b.use :input, class: 'form-select', error_class: 'is-invalid', valid_class: 'is-valid'
    b.use :error, wrap_with: { tag: 'div', class: 'invalid-feedback' }
    b.use :hint, wrap_with: { tag: 'div', class: 'form-text' }
  end

  # Set default wrapper
  config.default_wrapper = :bootstrap

  # Configure button class
  config.button_class = 'btn btn-primary'

  # Configure boolean style
  config.boolean_style = :nested

  # Configure collection wrapper class
  config.collection_wrapper_class = 'mb-3'

  # Configure item wrapper class
  config.item_wrapper_class = 'form-check'

  # Configure label text for boolean inputs
  config.boolean_label_class = 'form-check-label'
end
