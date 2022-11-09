#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/teeworlds_client'

client = TeeworldsClient.new(verbose: false)

client.connect('localhost', 8377, detach: true)

sleep 1
client.send_chat('foo')

client.connect('localhost', 8377, detach: true)

sleep 1
client.send_chat('bar')
