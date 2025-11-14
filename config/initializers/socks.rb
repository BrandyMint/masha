# frozen_string_literal: true

if Rails.env.development? && ENV['SOCKS_SERVER']
  require 'socksify'
  Rails.logger.debug 'Initialize socks'
  TCPSocket.socks_server = ENV['SOCKS_SERVER']
  TCPSocket.socks_port = ENV.fetch('SOCKS_PORT', nil)
  TCPSocket.socks_username = ENV.fetch('SOCKS_USERNAME', nil)
  TCPSocket.socks_password = ENV.fetch('SOCKS_PASSWORD', nil)
end
