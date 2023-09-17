# frozen_string_literal: true

require 'rake'

Gem::Specification.new do |s|
  s.name        = 'teeworlds_network'
  s.version     = '0.0.4'
  s.summary     = 'teeworlds 0.7 network protocol (client and server)'
  s.description = <<-DESC
  A library wrapping the network protocol of the game teeworlds.
  Only supporting the version 0.7 of the teeworlds protocol.
  DESC
  s.authors     = ['ChillerDragon']
  s.email       = 'ChillerDragon@gmail.com'
  s.files       = FileList[
    'lib/**/*.rb'
  ]
  s.required_ruby_version = '>= 3.1.2'
  s.add_dependency 'huffman_tw', '~> 0.0.1'
  s.add_dependency 'rspec', '~> 3.9.0'
  s.homepage    = 'https://github.com/ChillerDragon/teeworlds_network'
  s.license     = 'Unlicense'
  s.metadata['rubygems_mfa_required'] = 'true'
  s.metadata['documentation_uri'] = 'https://github.com/ChillerDragon/teeworlds_network/tree/master/docs'
end
