class ApplicationDecorator < Draper::Decorator

  private

  def arbre assignes = {}, &block
    Arbre::Context.new assignes, helpers, &block
  end
end
