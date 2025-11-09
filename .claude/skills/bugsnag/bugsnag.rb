#!/usr/bin/env ruby

# Main entry point for Bugsnag skill
require_relative 'cli'

# Handle execution through MCP or direct CLI
if ARGV.empty?
  # MCP mode - read from stdin or handle through environment
  puts "Bugsnag skill initialized. Use 'help' for available commands."
else
  # CLI mode - direct execution
  cli = BugsnagCLI.new
  cli.run(ARGV)
end