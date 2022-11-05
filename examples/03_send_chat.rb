#!/usr/bin/env ruby
# frozen_string_literal: true

# Chat spamming client

require_relative '../lib/teeworlds-client'

client = TeeworldsClient.new(verbose: true)

# connect to localhost and detach a background thread
client.connect('localhost', 8303, detach: true)

loop do
  # send a chat message every 5 seconds
  sleep 5
  client.send_chat('hello friends!')
end
