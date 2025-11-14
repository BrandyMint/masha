# frozen_string_literal: true

class ApplicationDecorator < Draper::Decorator
  private

  def arbre(assignes = {}, &)
    Arbre::Context.new(assignes, helpers, &)
  end
end
