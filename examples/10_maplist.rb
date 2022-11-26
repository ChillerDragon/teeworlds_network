#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/teeworlds_client'

client = TeeworldsClient.new

client.on_connected do |_|
  client.rcon_auth(password: 'rcon')
end

client.on_maplist_entry_add do |ctx|
  puts ctx.message.name
end

# connect and block main thread
client.connect('localhost', 8303, detach: false)
