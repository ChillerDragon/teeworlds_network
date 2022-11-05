#!/usr/bin/env ruby

require_relative 'lib/teeworlds-client'

args = {verbose: false, ip: nil, port: nil}

ARGV.each do |arg|
  if arg == '--help' || arg == '-h'
    puts "usage: teeworlds.rb [OPTIONS..] [host] [port]"
    echo "options:"
    echo "  --help|-h        show this help"
    echo "  --verbose|-v     verbose output"
    echo "example:"
    echo "  teeworlds.rb --verbose localhost 8303"
    exit(0)
  elsif arg == '--verbose' || arg == '-v'
    args[:verbose] = true
  elsif args[:ip].nil?
    args[:ip] = arg
  elsif args[:port].nil?
    args[:port] = arg.to_i
  end
end

args[:ip] = args[:ip] || '127.0.0.1'
args[:port] = args[:port] || 8303

client = TeeworldsClient.new(verbose: args[:verbose])

client.on_chat do |msg|
  puts "[chat] #{msg}"
end

client.on_client_info do |ctx|
  puts "'#{ctx.data[:player].name}' joined the game#{reason}"
end

client.on_client_drop do |ctx|
  unless ctx.data[:silent]
    reason = ctx.data[:reason] ? " (#{ctx.data[:reason]})" : ''
    puts "'#{ctx.data[:player].name}' left the game#{reason}"
  end
end

Signal.trap('INT') do
  client.disconnect
end

# connect and detach thread
client.connect(args[:ip], args[:port], detach: false)
