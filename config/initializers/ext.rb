# frozen_string_literal: true

module SimpleForm
  module Inputs
    class Base
      protected

      def arbre(assigns, &)
        Arbre::Context.new(assigns, template, &)
      end
    end
  end
end
