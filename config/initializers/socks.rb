if Rails.env.development? && ENV['SOCKS_SERVER']
  require 'socksify'
  puts 'Initialize socks'
  TCPSocket::socks_server = ENV['SOCKS_SERVER']
  TCPSocket::socks_port = ENV['SOCKS_PORT']
  TCPSocket::socks_username = ENV['SOCKS_USERNAME']
  TCPSocket::socks_password = ENV['SOCKS_PASSWORD']
end
