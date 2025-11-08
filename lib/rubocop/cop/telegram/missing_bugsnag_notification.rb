# frozen_string_literal: true

module RuboCop
  module Cop
    module Telegram
      # Checks for missing Bugsnag notification in rescue blocks
      #
      # @example
      #   # bad
      #   rescue StandardError => e
      #     Rails.logger.error e.message
      #     respond_with :message, text: 'Error'
      #   end
      #
      #   # good
      #   rescue StandardError => e
      #     notify_bugsnag(e)
      #     respond_with :message, text: 'Error'
      #   end
      class MissingBugsnagNotification < Base
        extend AutoCorrector

        MSG = 'Missing Bugsnag notification in rescue block. Use notify_bugsnag(e) or similar.'

        def on_rescue(node)
          rescue_clauses = node.children.select { |child| child.is_a?(AST::Node) && child.type == :resbody }

          rescue_clauses.each do |resbody|
            next unless has_exception_variable?(resbody)
            next if has_bugsnag_notification?(resbody)

            add_offense(resbody, message: MSG) do |corrector|
              exception_var = find_exception_variable(resbody)
              if exception_var
                indentation = ' ' * (resbody.loc.column + 2)
                bugsnag_code = "#{indentation}notify_bugsnag(#{exception_var})\n"
                corrector.insert_before(resbody.loc.expression, bugsnag_code)
              end
            end
          end
        end

        private

        def has_exception_variable?(resbody)
          !find_exception_variable(resbody).nil?
        end

        def find_exception_variable(resbody)
          # resbody structure: [:resbody, exceptions, variable_name, body]
          return nil unless resbody.children.size >= 2

          variable_node = resbody.children[1]
          return nil unless variable_node && variable_node.type == :lvasgn

          variable_node.children.first.to_s
        end

        def has_bugsnag_notification?(resbody)
          return false unless resbody.children.size >= 3

          body_node = resbody.children[2]
          return false unless body_node

          bugsnag_calls = %i[notify_bugsnag Bugsnag.notify]

          body_node.each_descendant(:send).any? do |send_node|
            method_name = send_node.method_name
            receiver = send_node.receiver&.source

            bugsnag_calls.include?(method_name) ||
            (receiver == 'Bugsnag' && method_name == :notify)
          end
        end
      end
    end
  end
end