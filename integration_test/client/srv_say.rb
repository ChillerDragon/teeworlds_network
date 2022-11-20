#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/teeworlds_client'

client = TeeworldsClient.new

connected = false

client.on_connected do |_|
  client.rcon_auth(password: 'rcon')
  connected = true
end

# this should nicley print the server message
client.on_chat do |_, msg|
  puts "[chat] #{msg}"
end

# connect and block main thread
client.connect('localhost', 8377, detach: true)

sleep 0.5 until connected

puts '[test] sending server hello'
client.rcon('say "hello"')
sleep 1

client.rcon('shutdown')
sleep 0.2

# this is also testing a disconnect
# if the server shutdown already
# should never crash
client.disconnect
