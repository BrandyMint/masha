module ApplicationHelper
  def user_roles user
    buffer = ''
    buffer << content_tag( :span, 'Супер-админ', :class => 'label label-important' ) if user.has_role? :admin
    buffer.html_safe
  end
end
