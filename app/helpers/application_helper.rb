module ApplicationHelper
  def user_roles user
    buffer = ''

    buffer << content_tag( :span, 'Супер-админ', :class => 'label label-important' )
      if user.is_root?

      end
    buffer
  end
end
