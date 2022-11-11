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
require_relative 'game_server'
require_relative 'message'

class Client
  attr_accessor :id, :addr

  def initialize(attr = {})
    @id = attr[:id]
    @addr = attr[:addr]
  end
end

class TeeworldsServer
  def initialize(options = {})
    @verbose = options[:verbose] || false
    @ip = '127.0.0.1'
    @port = 8303
    @game_server = GameServer.new(self)
    @clients = {}
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
      # TODO: proper tick speed sleep
      sleep 0.001
    end
  end

  def on_system_chunk(chunk)
    puts "got system chunk: #{chunk}"
  end

  def process_chunk(chunk, packet)
    unless chunk.sys
      on_system_chunk(chunk)
      return
    end
    puts "proccess chunk with msg: #{chunk.msg}"
    case chunk.msg
    when NETMSG_INFO
      @game_server.on_info(chunk, packet)
    else
      puts "Unsupported system msg: #{chunk.msg}"
      exit(1)
    end
  end

  def on_client_packet(packet)
    chunks = BigChungusTheChunkGetter.get_chunks(packet.payload)
    chunks.each do |chunk|
      if chunk.flags_vital && !chunk.flags_resend
        @netbase.ack = (@netbase.ack + 1) % NET_MAX_SEQUENCE
        puts "got ack: #{@netbase.ack}" if @verbose
      end
      process_chunk(chunk, packet)
    end
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

  def send_map(addr)
    data = []
    data += Packer.pack_str(@game_server.map.name)
    data += Packer.pack_int(@game_server.map.crc)
    data += Packer.pack_int(@game_server.map.size)
    data += Packer.pack_int(8) # chunk num?
    data += Packer.pack_int(MAP_CHUNK_SIZE)
    data += @game_server.map.sha256_arr # poor mans pack_raw()
    msg = NetChunk.create_non_vital_header(size: data.size + 1) +
          [pack_msg_id(NETMSG_MAP_CHANGE, system: true)] +
          data
    @netbase.send_packet(msg, 1, addr:)
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
    puts 'got connection, sending accept'

    id = get_next_client_id
    if id == -1
      puts 'server full drop packet. TODO: tell the client'
      return
    end
    client = Client.new(id:, addr: packet.addr)
    @clients[id] = client
    @netbase.send_packet([NET_CTRLMSG_ACCEPT], 0, control: true, addr: packet.addr)
  end

  def on_packet(packet)
    # process connless packets data
    if packet.flags_control
      on_ctrl_message(packet)
    else # process non-connless packets
      on_client_packet(packet)
    end
  end

  def get_next_client_id
    (0..MAX_CLIENTS).each do |i|
      next if @clients[i]

      return i
    end
    -1
  end

  def tick
    begin
      data, sender_inet_addr = @s.recvfrom_nonblock(1400)
    rescue IO::EAGAINWaitReadable
      data = nil
      sender_inet_addr = nil
    end
    return unless data

    packet = Packet.new(data, '<')
    packet.addr.ip = sender_inet_addr[2] # or 3 idk bot 127.0.0.1 in my local test case
    packet.addr.port = sender_inet_addr[1]
    @clients.each do |id, client|
      next unless packet.addr.eq(client.addr)

      packet.client_id = id
    end

    puts packet.to_s if @verbose
    on_packet(packet)
  end
end
