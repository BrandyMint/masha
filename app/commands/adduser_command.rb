# frozen_string_literal: true

class AdduserCommand < BaseCommand
  def call(project_slug = nil, username = nil, role = 'member', *)
    # Delegate to new UsersCommand functionality first
    users_response = UsersCommand.new(controller).call('add', project_slug, username, role)

    # If users command returns a response, prepend deprecation warning to it
    if users_response.is_a?(Array)
      # Add deprecation warning as first message
      warning_message = { text: '⚠️ Команда /adduser устарела. Используйте /users add вместо неё.' }
      users_response.unshift(warning_message)
      users_response
    elsif users_response
      # Single response - add warning before it
      warning_message = { text: '⚠️ Команда /adduser устарела. Используйте /users add вместо неё.' }
      [warning_message, users_response]
    else
      # No response from users command - show only warning
      respond_with :message, text: '⚠️ Команда /adduser устарела. Используйте /users add вместо неё.'
    end
  end

  # Legacy callback handlers for backward compatibility
  def adduser_project_callback_query(project_slug)
    # Show deprecation warning
    edit_message :text, text: '⚠️ Этот диалог устарел. Используйте /users add для добавления пользователей.'
  end

  def adduser_username_input(username, *)
    # Show deprecation warning
    respond_with :message, text: '⚠️ Этот процесс устарел. Используйте /users add для добавления пользователей.'
  end

  def adduser_role_callback_query(role)
    # Show deprecation warning
    edit_message :text, text: '⚠️ Этот процесс устарел. Используйте /users add для добавления пользователей.'
  end
end
