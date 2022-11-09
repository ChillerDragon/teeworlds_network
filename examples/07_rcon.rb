#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/teeworlds_client'

client = TeeworldsClient.new

client.on_connected do |_|
  client.rcon_auth(password: '123')
  client.rcon('shutdown')
end

client.on_rcon_line do |ctx|
  puts "[rcon] #{ctx.data[:line]}"
end

# connect and block main thread
client.connect('localhost', 8303, detach: false)
