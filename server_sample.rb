#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/teeworlds_server'

srv = TeeworldsServer.new(verbose: false)

srv.on_chat do |context, msg|
  context.cancel

  puts "[chat] #{msg.author.name}: #{msg.message}"
end

srv.run('127.0.0.1', 8303, detach: false)
