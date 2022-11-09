# frozen_string_literal: true

require 'socket'

require_relative 'string'
require_relative 'array'
require_relative 'bytes'
require_relative 'network'
require_relative 'packet'
require_relative 'chunk'
require_relative 'net_base'
require_relative 'net_addr'
require_relative 'packer'

class TeeworldsServer
  def initialize(options = {})
    @verbose = options[:verbose] || false
    @ip = '127.0.0.1'
    @port = 8303
  end

  def run(ip, port)
    @server_token = (1..4).to_a.map { |_| rand(0..255) }
    @server_token = @server_token.map { |b| b.to_s(16) }.join
    puts "server token #{@server_token}"
    @netbase = NetBase.new
    NetChunk.reset
    @ip = ip
    @port = port
    puts "listening on #{@ip}:#{@port} .."
    @s = UDPSocket.new
    @s.bind(@ip, @port)
    @netbase.bind(@s)
    loop do
      tick
    end
  end

  def on_client_packet(_packet)
    puts 'got client packet'
  end

  def on_ctrl_message(packet)
    u = Unpacker.new(packet.payload)
    msg = u.get_int
    puts "got ctrl msg: #{msg}"
    case msg
    when NET_CTRLMSG_TOKEN then on_ctrl_token(packet)
    when NET_CTRLMSG_CONNECT then on_ctrl_connect(packet)
    when NET_CTRLMSG_KEEPALIVE then on_ctrl_keep_alive(packet)
    when NET_CTRLMSG_CLOSE then on_ctrl_close(packet)
    else
      puts "Uknown control message #{msg}"
      exit(1)
    end
  end

  def send_ctrl_with_token(addr, token)
    msg = [NET_CTRLMSG_TOKEN] + token
    @netbase.send_packet(msg, 0, control: true, addr:)
  end

  def on_ctrl_token(packet)
    u = Unpacker.new(packet.payload[1..])
    token = u.get_raw(4)
    # puts "got token #{token.map { |b| b.to_s(16) }.join('')}"
    send_ctrl_with_token(packet.addr, token)
  end

  def on_ctrl_keep_alive(packet)
    puts "Got keep alive from #{packet.addr}" if @verbose
  end

  def on_ctrl_close(packet)
    puts "Client closed the connection #{packet.addr}"
  end

  def on_ctrl_connect(packet)
    puts "Got connect from #{packet.addr}"
  end

  def on_packet(packet)
    # process connless packets data
    if packet.flags_control
      on_ctrl_message(packet)
    else # process non-connless packets
      on_client_packet(packet)
    end
  end

  def tick
    begin
      data, client = @s.recvfrom_nonblock(1400)
    rescue IO::EAGAINWaitReadable
      data = nil
      client = nil
    end
    return unless data

    packet = Packet.new(data, '<')
    packet.addr.ip = client[2] # or 3 idk bot 127.0.0.1 in my local test case
    packet.addr.port = client[1]
    puts packet.to_s if @verbose
    on_packet(packet)

    # TODO: proper tick speed sleep
    sleep 0.001
  end
end
