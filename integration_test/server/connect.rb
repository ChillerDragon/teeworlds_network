#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/teeworlds_server'

server = TeeworldsServer.new(verbose: false)

server.run('127.0.0.1', 8377)
