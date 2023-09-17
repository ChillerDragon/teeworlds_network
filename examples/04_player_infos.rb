#!/usr/bin/env ruby
# frozen_string_literal: true

# Set custom skin and other player infos

require_relative '../lib/teeworlds_client'

client = TeeworldsClient.new(verbose: true)

# all keys are optional
# if not provided they will fall back to the default value
client.set_startinfo(
  name: 'ruby gamer',
  clan: '',
  country: -1,
  body: 'spiky',
  marking: 'duodonny',
  decoration: '',
  hands: 'standard',
  feet: 'standard',
  eyes: 'standard',
  custom_color_body: 0,
  custom_color_marking: 0,
  custom_color_decoration: 0,
  custom_color_hands: 0,
  custom_color_feet: 0,
  custom_color_eyes: 0,
  color_body: 0,
  color_marking: 0,
  color_decoration: 0,
  color_hands: 0,
  color_feet: 0,
  color_eyes: 0
)

# connect to localhost and block the current thread
client.connect('localhost', 8303, detach: false)
