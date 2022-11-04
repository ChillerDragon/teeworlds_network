#!/usr/bin/env ruby

require 'socket'

require_relative 'string'
require_relative 'array'
require_relative 'bytes'
require_relative 'network'
require_relative 'packet'
require_relative 'chunk'
require_relative 'server_info'
require_relative 'net_base'
require_relative 'packer'
require_relative 'player'
require_relative 'game_client'

class TeeworldsClient
  attr_reader :state, :hooks

  def initialize(options = {})
    @verbose = options[:verbose] || false
    @state = NET_CONNSTATE_OFFLINE
    @ip = 'localhost'
    @port = 8303
    @packet_flags = {}
    @hooks = {}
    @thread_running = false
    @signal_disconnect = false
    @game_client = GameClient.new(self)
    @start_info = {
      name: "ruby gamer",
      clan: "",
      country: -1,
      body: "spiky",
      marking: "duodonny",
      decoration: "",
      hands: "standard",
      feet: "standard",
      eyes: "standard",
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
    }
  end

  def hook_chat(&block)
    @hooks[:chat] = block
  end

  def send_chat(str)
    @netbase.send_packet(
      NetChunk.create_vital_header({vital: true}, 4 + str.length) +
      [
        pack_msg_id(NETMSGTYPE_CL_SAY),
        CHAT_ALL,
        64 # should use TARGET_SERVER (-1) instead of hacking 64 in here
      ] +
      Packer.pack_str(str)
    )
  end

  def connect(ip, port, options = {})
    options[:detach] = options[:detach] || false
    if options[:detach]
      if @thread_running
        puts "Error: connection thread already running call disconnect() first"
        return
      end
    end
    disconnect
    @signal_disconnect = false
    @ticks = 0
    @game_client = GameClient.new(self)
    # me trying to write cool code
    @client_token = (1..4).to_a.map { |_| rand(0..255) }
    @client_token = @client_token.map { |b| b.to_s(16) }.join('')
    puts "client token #{@client_token}"
    @netbase = NetBase.new
    @netbase.client_token = @client_token
    NetChunk.reset
    @ip = ip
    @port = port
    puts "connecting to #{@ip}:#{@port} .."
    @s = UDPSocket.new
    @s.connect(ip, port)
    puts "client port: #{@s.addr[1]}"
    @netbase.connect(@s, @ip, @port)
    @token = nil
    send_ctrl_with_token
    if options[:detach]
      @thread_running = true
      Thread.new do
        connection_loop
      end
    else
      connection_loop
    end
  end

  def disconnect
    puts "disconnecting."
    unless @netbase.nil?
      @netbase.send_packet([NET_CTRLMSG_CLOSE], 0, control: true)
    end
    unless @s.nil?
      @s.close
    end
    @signal_disconnect = true
  end

  def set_startinfo(info)
    info.each do |key, value|
      unless @start_info.key?(key)
        puts "Error: invalid start info key '#{key}'"
        puts "       valid keys: #{@start_info.keys}"
        exit 1
      end
      @start_info[key] = value
    end
  end

  private

  def connection_loop
      until @signal_disconnect
        tick
        # todo: proper tick speed sleep
        sleep 0.001
      end
      @thread_running = false
      @signal_disconnect = false
  end

  def send_msg(data)
    @netbase.send_packet(data)
  end

  def send_ctrl_keepalive()
    @netbase.send_packet([NET_CTRLMSG_KEEPALIVE], 0, control: true)
  end

  def send_msg_connect()
    msg = [NET_CTRLMSG_CONNECT] + str_bytes(@client_token) + Array.new(501, 0x00)
    @netbase.send_packet(msg, 0, control: true)
  end

  def send_ctrl_with_token()
    @state = NET_CONNSTATE_TOKEN
    msg = [NET_CTRLMSG_TOKEN] + str_bytes(@client_token) + Array.new(512, 0x00)
    @netbase.send_packet(msg, 0, control: true)
  end

  def send_info()
    data = []
    data += Packer.pack_str(GAME_NETVERSION)
    data += Packer.pack_str("password")
    data += Packer.pack_int(CLIENT_VERSION)
    msg = NetChunk.create_vital_header({vital: true}, data.size + 1) +
      [pack_msg_id(NETMSG_INFO, system: true)] +
      data

    @netbase.send_packet(msg, 1)
  end

  def send_msg_startinfo()
    data = []

    @start_info.each do |key, value|
      if value.class == String
        data += Packer.pack_str(value)
      elsif value.class == Integer
        data += Packer.pack_int(value)
      else
        puts "Error: invalid startinfo #{key}: #{value}"
        exit 1
      end
    end

    @netbase.send_packet(
      NetChunk.create_vital_header({vital: true}, data.size + 1) +
      [pack_msg_id(NETMSGTYPE_CL_STARTINFO, system: false)] +
      data
    )
  end

  def send_msg_ready()
    @netbase.send_packet(
      NetChunk.create_vital_header({vital: true}, 1) +
      [pack_msg_id(NETMSG_READY, system: true)])
  end

  def send_enter_game()
    @netbase.send_packet(
      NetChunk.create_vital_header({vital: true}, 1) +
      [pack_msg_id(NETMSG_ENTERGAME, system: true)])
  end

  ##
  # Turns int into network byte
  #
  # Takes a NETMSGTYPE_CL_* integer
  # and returns a byte that can be send over
  # the network
  def pack_msg_id(msg_id, options = {system: false})
    (msg_id << 1) | (options[:system] ? 1 : 0)
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

  def on_emoticon(chunk)
    # puts "Got emoticon flags: #{chunk.flags}"
  end

  def on_message(chunk)
    case chunk.msg
    when NETMSGTYPE_SV_READYTOENTER then send_enter_game
    when NETMSGTYPE_SV_CLIENTINFO then @game_client.on_player_join(chunk)
    when NETMSGTYPE_SV_EMOTICON then on_emoticon(chunk)
    when NETMSGTYPE_SV_CHAT then @game_client.on_chat(chunk)
    else
      if @verbose
        puts "todo non sys chunks. skipped msg: #{chunk.msg}"
      end
    end
  end

  def process_chunk(chunk)
    if !chunk.sys
      on_message(chunk)
      return
    end
    puts "proccess chunk with msg: #{chunk.msg}"
    case chunk.msg
    when NETMSG_MAP_CHANGE
      send_msg_ready
    when NETMSG_SERVERINFO
      puts "ignore server info for now"
    when NETMSG_CON_READY
      send_msg_startinfo
    when NETMSG_NULL
      # should we be in alert here?
    else
      puts "Unsupported system msg: #{chunk.msg}"
      exit(1)
    end
  end

  def process_server_packet(packet)
    data = packet.payload
    if data.size.zero?
      puts "Error: packet payload is empty"
      puts packet.to_s
      return
    end
    chunks = BigChungusTheChunkGetter.get_chunks(data)
    chunks.each do |chunk|
      if chunk.flags_vital && !chunk.flags_resend
        @netbase.ack = (@netbase.ack + 1) % NET_MAX_SEQUENCE
        if @verbose
          puts "got ack: #{@netbase.ack}"
        end
      end
      process_chunk(chunk)
    end
  end

  def tick
    # puts "tick"
    begin
      pck = @s.recvfrom_nonblock(1400)
    rescue IO::EAGAINWaitReadable
      pck = nil
    end
    if pck.nil? && @token.nil?
      @wait_for_token = @wait_for_token || 0
      @wait_for_token += 1
      if @wait_for_token > 6
        @token = nil
        send_ctrl_with_token
        puts "retrying connection ..."
      end
    end
    return unless pck

    data = pck.first

    packet = Packet.new(data, '<')
    if @verbose
      puts packet.to_s
    end

    # process connless packets data
    if packet.flags_control
      msg = data[PACKET_HEADER_SIZE].unpack("C*").first
      on_ctrl_message(msg, data[(PACKET_HEADER_SIZE + 1)..])
    else # process non-connless packets
      process_server_packet(packet)
    end

    @ticks += 1
    if @ticks % 8 == 0
      send_ctrl_keepalive
    end
    if @ticks % 20 == 0
      send_chat("hello world")
    end
  end
end

