#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/teeworlds_server'

server = TeeworldsServer.new(verbose: false)

server.on_chat do |context, chat_msg|
  context.cancel

  puts "[testchat] #{chat_msg.author.name}: #{chat_msg.message}"
end

server.run('127.0.0.1', 8377)
