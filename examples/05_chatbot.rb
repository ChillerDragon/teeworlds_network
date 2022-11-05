#!/usr/bin/env ruby

# Reply to ! prefixed commands in chat
#
# ruby ./examples/05_chatbot.rb
#
# Then connect to localhost and write !ping in the chat

require_relative '../lib/teeworlds-client'

client = TeeworldsClient.new(verbose: false)

client.on_chat do |msg|
  if msg.message[0] == '!'
    case msg.message[1..]
    when 'ping' then client.send_chat('pong')
    when 'whoami' then client.send_chat("You are: #{msg.author.name}")
    when 'list' then client.send_chat(client.game_client.players.values.map(&:name).join(', '))
    else client.send_chat('Unkown command! Commands: !ping, !whoami, !list')
    end
  end
end

# properly disconnect on ctrl+c
Signal.trap('INT') do
  client.disconnect
end

# connect to localhost and block the current thread
client.connect('localhost', 8303, detach: false)
