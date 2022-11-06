#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/teeworlds-client'

client = TeeworldsClient.new

client.on_connected do |_|
  client.rcon_auth(password: 'rcon')
  client.rcon('shutdown')
end

client.on_rcon_line do |ctx|
  puts "[rcon] #{ctx.data[:line]}"
end

# connect and block main thread
client.connect('localhost', 8377, detach: false)
