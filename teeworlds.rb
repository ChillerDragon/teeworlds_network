#!/usr/bin/env ruby

require 'socket'

require_relative 'lib/string'
require_relative 'lib/array'
require_relative 'lib/bytes'
require_relative 'lib/network'
require_relative 'lib/packet'
require_relative 'lib/chunk'
require_relative 'lib/server_info'

class NetBase
  attr_accessor :client_token, :server_token, :ack

  def initialize
    @ip = nil
    @port = nil
    @s = nil
    @ack = 0
  end

  def connect(socket, ip, port)
    @s = socket
    @ip = ip
    @port = port
    @ack = 0
  end

  ##
  # Sends a packing setting the proper header for you
  #
  # @param payload [Array] The Integer list representing the data after the header
  # @param flags [Hash] Packet header flags for more details check the class +PacketFlags+
  def send_packet(payload, flags = {})
    # unsigned char flags_ack;    // 6bit flags, 2bit ack
    # unsigned char ack;          // 8bit ack
    # unsigned char numchunks;    // 8bit chunks
    # unsigned char token[4];     // 32bit token
    # // ffffffaa
    # // aaaaaaaa
    # // NNNNNNNN
    # // TTTTTTTT
    # // TTTTTTTT
    # // TTTTTTTT
    # // TTTTTTTT
    flags_bits = PacketFlags.new(flags).bits
    num_chunks = 0 # todo
    header_bits =
      '00' + # unused flags?           # ff
      flags_bits +                     #    ffff
      @ack.to_s(2).rjust(10, '0') +    #        aa aaaa aaaa
      num_chunks.to_s(2).rjust(8, '0') # NNNN NNNN

    # puts "header bits: #{header_bits}"
    header = header_bits.chars.groups_of(8).map do |eight_bits|
      eight_bits.join('').to_i(2)
    end
    # puts "header bytes: #{str_hex(header.pack("C*"))}"

    # header = [0x00, 0x00, 0x01] + str_bytes(@server_token)
    header = header + str_bytes(@server_token)
    data = (header + payload).pack('C*')
    @s.send(data, 0, @ip, @port)

    p = Packet.new(data, '>')
    puts p.to_s
  end
end

class TwClient
  attr_reader :state

  def initialize
    @client_token = MY_TOKEN.map { |b| b.to_s(16) }.join('')
    puts "client token #{@client_token}"
    @s = UDPSocket.new
    @state = NET_CONNSTATE_OFFLINE
    @ip = 'localhost'
    @port = 8303
    @packet_flags = {}
    @ticks = 0
    @netbase = NetBase.new
    @netbase.client_token = @client_token
  end

  def send_msg(data)
    @netbase.send_packet(data)
  end

  def send_ctrl_keepalive()
    @netbase.send_packet([NET_CTRLMSG_KEEPALIVE])
  end

  def send_msg_connect()
    header = [0x04, 0x00, 0x00] + str_bytes(@token)
    msg = header + [NET_CTRLMSG_CONNECT] + str_bytes(@client_token) + Array.new(501, 0x00)
    @s.send(msg.pack('C*'), 0, @ip, @port)
  end

  def send_ctrl_with_token()
    @state = NET_CONNSTATE_TOKEN
    @s.send(MSG_TOKEN.pack('C*'), 0, @ip, @port)
  end

  def send_info()
    send_msg(MSG_INFO)
  end

  def send_msg_startinfo()
    header = [0x00, 0x04, 0x01] + str_bytes(@token)
    msg = header + MSG_STARTINFO
    @s.send(msg.pack('C*'), 0, @ip, @port)
  end

  def send_msg_ready()
    header = [0x00, 0x01, 0x01] + str_bytes(@token)
    msg = header + [0x40, 0x01, 0x02, 0x25]
    @s.send(msg.pack('C*'), 0, @ip, @port)
  end

  def send_enter_game()
    header = [0x00, 0x07, 0x01] + str_bytes(@token)
    msg = header + [0x40, 0x01, 0x04, 0x27]
    @s.send(msg.pack('C*'), 0, @ip, @port)
  end

  def send_input
    header = [0x10, 0x0A, 01] + str_bytes(@token)
    random_compressed_input = [
      0x4D, 0xE9, 0x48, 0x13, 0xD0, 0x0B, 0x6B, 0xFC, 0xB7, 0x2B, 0x6E, 0x00, 0xBA
    ]
    # this wont work we need to ack the ticks
    # and then compress it
    # CMsgPacker Msg(NETMSG_INPUT, true);
    # Msg.AddInt(m_AckGameTick);
    # Msg.AddInt(m_PredTick);
    # Msg.AddInt(Size);
    msg = header + random_compressed_input
    @s.send(msg.pack('C*'), 0, @ip, @port)
  end

  def on_msg_token(data)
      @token = bytes_to_str(data)
      @netbase.server_token = @token
      puts "Got token #{@token}"
      send_msg_connect()
  end

  def on_msg_accept
    puts "got accept. connection online"
    @state = NET_CONNSTATE_ONLINE
    send_info
  end

  def on_msg_close
    puts "got NET_CTRLMSG_CLOSE"
  end

  def get_strings(data)
    strings = []
    str = ""
    data.chars.each do |b|
      # use a bunch of control characters as delimiters
      # https://en.wikipedia.org/wiki/Control_character
      if (0x00..0x0F).to_a.include?(b.unpack('C*').first)
        strings.push(str) unless str.length.zero?
        str = ""
        next
      end

      str += b
    end
    strings
  end

  def on_msg_map_change(data)
    mapname = get_strings(data).first
    puts "map: #{mapname}"
    send_msg_ready()
  end

  def connect(ip, port)
    @ip = ip
    @port = port
    puts "connecting to #{@ip}:#{@port} .."
    @s.connect(ip, port)
    @netbase.connect(@s, @ip, @port)
    send_ctrl_with_token
    loop do
      tick
      # todo: proper tick speed sleep
      sleep 0.001
    end
  end

  def on_motd(data)
    puts "motd: #{get_strings(data)}"
  end

  def on_playerinfo(data)
    puts "playerinfo: #{get_strings(data).join(', ')}"
  end

  # CClient::ProcessConnlessPacket
  def on_ctrl_message(msg, data)
    case msg
    when NET_CTRLMSG_TOKEN then on_msg_token(data)
    when NET_CTRLMSG_ACCEPT then on_msg_accept
    when NET_CTRLMSG_CLOSE then on_msg_close
    when NET_CTRLMSG_KEEPALIVE then # silently ignore keepalive
    else
        puts "Uknown control message #{msg}"
        exit(1)
    end
  end

  def process_chunk(chunk)
    if !chunk.sys
      puts "todo non sys chunks. skipped msg: #{chunk.msg}"
      return
    end
    puts "proccess chunk with msg: #{chunk.msg}"
    case chunk.msg
    when NETMSG_MAP_CHANGE
      send_msg_ready
    when NETMSG_CON_READY
      send_msg_startinfo
    else
      puts "Unsupported system msg: #{chunk.msg}"
      exit(1)
    end
  end

  def process_server_packet(data)
    chunks = BigChungusTheChunkGetter.get_chunks(data)
    chunks.each do |chunk|
      if chunk.flags_vital
        @netbase.ack = (@netbase.ack + 1) % NET_MAX_SEQUENCE
        puts "got ack: #{@netbase.ack}"
      end
      process_chunk(chunk)
    end
  end

  def tick
    # puts "tick"
    begin
      pck = @s.recvfrom_nonblock(1400)
    rescue
      pck = nil
    end
    return unless pck

    data = pck.first

    packet = Packet.new(data, '<')
    puts packet.to_s

    # process connless packets data
    if packet.flags_control
      msg = data[PACKET_HEADER_SIZE].unpack("C*").first
      on_ctrl_message(msg, data[(PACKET_HEADER_SIZE + 1)..])
    else # process non-connless packets
      process_server_packet(packet.payload)
    end

    @ticks += 1
    if @ticks % 10 == 0
      send_ctrl_keepalive
    end
  end

  def disconnect
    @s.close
  end
end

client = TwClient.new

client.connect(ARGV[0] || "localhost", ARGV[1] ? ARGV[1].to_i : 8303)

