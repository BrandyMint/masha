# frozen_string_literal: true

module Telegram
  # Routes callbacks to appropriate command classes based on prefixes
  # Provides convention-based routing from callback data to command handlers
  class CallbackRouter
    # Mapping of callback prefixes to command classes
    CALLBACK_PREFIXES = {
      'rename' => 'RenameCommand',
      'adduser' => 'AdduserCommand',
      'edit' => 'EditCommand',
      'select_project' => 'AddCommand'
    }.freeze

    # Complex callbacks that should use legacy handling during migration
    LEGACY_PREFIXES = %w[edit_page].freeze

    class << self
      # Main routing method - delegates callbacks to appropriate command classes
      def route(controller, callback_data)
        prefix = extract_prefix(callback_data)

        # Skip routing for complex callbacks during migration
        if LEGACY_PREFIXES.include?(prefix)
          return false
        end

        command_class_name = CALLBACK_PREFIXES[prefix]
        return false unless command_class_name

        # Ensure command class exists and has callback handling
        unless command_class_available?(command_class_name)
          Rails.logger.warn "Command class #{command_class_name} not available for callback routing"
          return false
        end

        begin
          command_instance = command_class_name.constantize.new(controller)
          command_instance.handle_callback(callback_data)
          true
        rescue => e
          Rails.logger.error "Error routing callback to #{command_class_name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          false
        end
      end

      # Extract prefix from callback data (e.g., "rename_project:slug" -> "rename")
      def extract_prefix(callback_data)
        return nil unless callback_data.is_a?(String) && callback_data.include?(':')

        parts = callback_data.split(':')
        if parts.first.include?('_')
          parts.first.split('_').first
        else
          parts.first
        end
      end

      # Check if command class is available and has callback handling capability
      def command_class_available?(class_name)
        return false unless class_name

        begin
          command_class = class_name.constantize
          # Check if command class exists and can handle callbacks
          command_class.instance_methods.include?(:handle_callback)
        rescue NameError
          false
        end
      end

      # Get all registered callback prefixes for debugging
      def registered_prefixes
        CALLBACK_PREFIXES.keys + LEGACY_PREFIXES
      end
    end
  end
end