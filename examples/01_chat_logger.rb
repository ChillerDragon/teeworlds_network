#!/usr/bin/env ruby

# Print all incoming chat messages to stdout

require_relative '../lib/teeworlds-client'

client = TeeworldsClient.new(verbose: false)

# print all incoming chat messages
# the variable `msg` holds an instance of the class `ChatMessage` which has the following fields
#
# msg.mode
# msg.client_id
# msg.target_id
# msg.message
# msg.author.id
# msg.author.team
# msg.author.name
# msg.author.clan
client.on_chat do |msg|
  puts "[chat] #{msg}"
end

# properly disconnect on ctrl+c
Signal.trap('INT') do
  client.disconnect
end

# connect to localhost and block the current thread
client.connect('localhost', 8303, detach: false)
