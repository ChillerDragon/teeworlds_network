#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/teeworlds_client'

args = {
  verbose: false,
  verbose_snap: false,
  ip: nil,
  port: nil
}

verbose_level = 0

def show_help
    puts 'usage: client_sample.rb [OPTIONS..] [host] [port]'
    puts 'options:'
    puts '  --help|-h             show this help'
    puts '  --verbose|-v          verbose output'
    puts '  --verbose-snap|-s     verbose snap item output'
    puts 'example:'
    puts '  client_sample.rb --verbose localhost 8303'
    puts '  client_sample.rb -s'
    puts '  client_sample.rb -vv ger.ddnet.org 8307'
    exit(0)
end

ARGV.each do |arg|
  if ['--help', '-h'].include?(arg)
    show_help
  elsif ['--verbose', '-v'].include?(arg)
    args[:verbose] = true
  elsif ['--verbose-snap', '-s'].include?(arg)
    args[:verbose_snap] = true
  elsif arg[0] == '-' && arg[1] != '-'
    # flags
    arg[1..].chars.each do |flag|
      case flag
      when 'v'
        verbose_level += 1
        args[:verbose] = true
        args[:verbose_snap] = true if verbose_level > 1
      when 'h'
        show_help
      when 's'
        args[:verbose_snap] = true
      else
        puts "Error: unknown flag '#{flag}'"
        exit(1)
      end
    end
  elsif args[:ip].nil?
    args[:ip] = arg
  elsif args[:port].nil?
    args[:port] = arg.to_i
  end
end

args[:ip] = args[:ip] || '127.0.0.1'
args[:port] = args[:port] || 8303

client = TeeworldsClient.new(args)

client.on_chat do |_, msg|
  puts "[chat] #{msg}"
end

client.on_client_info do |ctx|
  puts "'#{ctx.data[:player].name}' joined the game"
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
