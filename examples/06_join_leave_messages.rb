#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/teeworlds-client'

client = TeeworldsClient.new

client.on_client_info do |ctx|
  puts "'#{ctx.data[:player].name}' joined the game#{reason}"
end

client.on_client_drop do |ctx|
  unless ctx.data[:silent]
    reason = ctx.data[:reason] ? " (#{ctx.data[:reason]})" : ''
    puts "'#{ctx.data[:player].name}' left the game#{reason}"
  end
end

Signal.trap('INT') do
  client.disconnect
end

# connect and detach thread
client.connect('localhost', 8303, detach: false)
