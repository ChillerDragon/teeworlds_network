# frozen_string_literal: true

require 'rake'

Gem::Specification.new do |s|
  s.name        = 'teeworlds-client'
  s.version     = '0.0.1'
  s.summary     = 'teeworlds 0.7 network protocol (client)'
  s.description = <<-DESC
  A library wrapping the network protocol of the game teeworlds.
  Supported protocol version 0.7 and only the client side.
  DESC
  s.authors     = ['ChillerDragon']
  s.email       = 'ChillerDragon@gmail.com'
  s.files       = FileList[
    'lib/*.rb'
  ]
  s.required_ruby_version = '>= 3.1.2'
  s.add_dependency 'huffman_tw', '~> 0.0.1'
  s.add_dependency 'rspec', '~> 3.9.0'
  s.homepage    = 'https://github.com/ChillerDragon/teeworlds-client'
  s.license     = 'Unlicense'
  s.metadata['rubygems_mfa_required'] = 'true'
end
