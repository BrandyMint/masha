class SimpleForm::Inputs::Base
  protected

  def arbre assigns, &block
    Arbre::Context.new assigns, template, &block
  end
end
