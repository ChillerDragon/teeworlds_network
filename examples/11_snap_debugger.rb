#!/usr/bin/env ruby
# frozen_string_literal: true

# connects to a server and prints color annotated snap items
# https://chillerdragon.github.io/teeworlds-protocol/img/snap_dump_07.png

require_relative '../lib/teeworlds_client'

client = TeeworldsClient.new(verbose: false, verbose_snap: true)

# connect to localhost and block the current thread
client.connect('localhost', 8303, detach: false)
