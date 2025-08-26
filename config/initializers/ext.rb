# frozen_string_literal: true

module SimpleForm
  module Inputs
    class Base
      protected

      def arbre(assigns, &block)
        Arbre::Context.new assigns, template, &block
      end
    end
  end
end
