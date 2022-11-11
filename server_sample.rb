#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/teeworlds_server'

srv = TeeworldsServer.new(verbose: true)
srv.run('127.0.0.1', 8303)
