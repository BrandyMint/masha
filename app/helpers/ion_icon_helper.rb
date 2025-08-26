# frozen_string_literal: true

module IonIconHelper
  # Add in <head> <script src="https://unpkg.com/ionicons@4.2.2/dist/ionicons.js"></script>
  #
  def ion_icon(icon, text: nil)
    buffer = content_tag 'ion-icon', '', name: icon
    buffer << content_tag(:span, text, class: 'ion-icon-text') if text.present?

    buffer
  end
end
