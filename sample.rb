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

client.set_startinfo(
      name: "ruby gamer")

client.hook_chat do |msg|
  puts "[chat] #{msg}"
end

Signal.trap('INT') do
  client.disconnect
end

# connect and detach thread
client.connect(args[:ip], args[:port], detach: true)

# after 2 seconds reconnect
# and block the main thread
sleep 2
client.connect(args[:ip], args[:port], detach: false)

