#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/teeworlds_client'

client = TeeworldsClient.new

client.on_connected do |_|
  puts 'block 1 rcon auth'
  client.rcon_auth(password: 'rcon')
end

client.on_connected do |_|
  puts 'block 2 rcon shutdown'
  client.rcon('shutdown')
end

client.on_disconnect do
  puts 'got disconnect'
  exit 0
end

# connect and block main thread
client.connect('localhost', 8377, detach: false)
