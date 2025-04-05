# frozen_string_literal: true

require 'socket'

require_relative 'string'
require_relative 'array'
require_relative 'bytes'
require_relative 'version'
require_relative 'network'
require_relative 'packet'
require_relative 'chunk'
require_relative 'messages/server_info'
require_relative 'net_base'
require_relative 'packer'
require_relative 'models/player'
require_relative 'game_client'
require_relative 'config'
require_relative 'connection'

class TeeworldsClient
  attr_reader :state, :hooks, :game_client, :verbose_snap
  attr_accessor :rcon_authed, :local_client_id

  def initialize(options = {})
    @verbose = options[:verbose] || false
    @verbose_snap = options[:verbose_snap] || false
    @state = NET_CONNSTATE_OFFLINE
    @ip = 'localhost'
    @port = 8303
    @local_client_id = 0
    @config = Config.new(file: options[:config])
    @hooks = {
      chat: [],
      map_change: [],
      client_info: [],
      client_drop: [],
      connected: [],
      disconnect: [],
      rcon_line: [],
      snapshot: [],
      input_timing: [],
      auth_on: [],
      auth_off: [],
      rcon_cmd_add: [],
      rcon_cmd_rem: [],
      tick: [],
      maplist_entry_add: [],
      maplist_entry_rem: []
    }
    @thread_running = false
    @signal_disconnect = false
    @game_client = GameClient.new(self)
    @start_info = {
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
    }
    @rcon_authed = false
  end

  def rcon_authed?
    @rcon_authed
  end

  def on_tick(&block)
    @hooks[:tick].push(block)
  end

  def on_auth_on(&block)
    @hooks[:auth_on].push(block)
  end

  def on_auth_off(&block)
    @hooks[:auth_off].push(block)
  end

  def on_rcon_cmd_add(&block)
    @hooks[:rcon_cmd_add].push(block)
  end

  def on_rcon_cmd_rem(&block)
    @hooks[:rcon_cmd_rem].push(block)
  end

  def on_maplist_entry_add(&block)
    @hooks[:maplist_entry_add].push(block)
  end

  def on_maplist_entry_rem(&block)
    @hooks[:maplist_entry_rem].push(block)
  end

  def on_chat(&block)
    @hooks[:chat].push(block)
  end

  def on_map_change(&block)
    @hooks[:map_change].push(block)
  end

  def on_client_info(&block)
    @hooks[:client_info].push(block)
  end

  def on_client_drop(&block)
    @hooks[:client_drop].push(block)
  end

  def on_connected(&block)
    @hooks[:connected].push(block)
  end

  def on_disconnect(&block)
    @hooks[:disconnect].push(block)
  end

  def on_rcon_line(&block)
    @hooks[:rcon_line].push(block)
  end

  def on_snapshot(&block)
    @hooks[:snapshot].push(block)
  end

  def on_input_timing(&block)
    @hooks[:input_timing].push(block)
  end

  def send_chat(str)
    @netbase.send_packet(
      NetChunk.create_header(vital: true, size: 4 + str.length) +
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
    if options[:detach] && @thread_running
      puts 'Error: connection thread already running call disconnect() first'
      return
    end
    disconnect
    @signal_disconnect = false
    @ticks = 0
    @game_client = GameClient.new(self)
    # me trying to write cool code
    @client_token = (1..4).to_a.map { |_| rand(0..255) }
    @client_token = @client_token.map { |b| b.to_s(16).rjust(2, '0') }.join
    puts "client token #{@client_token}"
    @netbase = NetBase.new(verbose: @verbose)
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

  # TODO: this is same in client and server
  #       move to NetBase???
  def send_ctrl_close
    @netbase&.send_packet([NET_CTRLMSG_CLOSE], chunks: 0, control: true)
  end

  def disconnect
    puts 'disconnecting.'
    send_ctrl_close unless @s.nil?
    @s&.close
    @s = nil
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

  def send_msg(data)
    @netbase.send_packet(data)
  end

  def send_ctrl_keepalive
    @netbase.send_packet([NET_CTRLMSG_KEEPALIVE], chunks: 0, control: true)
  end

  def send_msg_connect
    msg = [NET_CTRLMSG_CONNECT] + str_bytes(@client_token) + Array.new(501, 0x00)
    @netbase.send_packet(msg, chunks: 0, control: true)
  end

  def send_ctrl_with_token
    @state = NET_CONNSTATE_TOKEN
    msg = [NET_CTRLMSG_TOKEN] + str_bytes(@client_token) + Array.new(512, 0x00)
    @netbase.send_packet(msg, chunks: 0, control: true)
  end

  def send_info
    data = []
    data += Packer.pack_str(GAME_NETVERSION)
    data += Packer.pack_str(@config.password)
    data += Packer.pack_int(CLIENT_VERSION)
    msg = NetChunk.create_header(vital: true, size: data.size + 1) +
          [pack_msg_id(NETMSG_INFO, system: true)] +
          data

    @netbase.send_packet(msg)
  end

  def rcon_auth(name, password = nil)
    if name.instance_of?(Hash)
      password = name[:password]
      name = name[:name]
    end
    if password.nil?
      raise "Error: password can not be empty\n" \
            "       provide two strings: name, password\n" \
            "       or a hash with the key :password\n" \
            "\n" \
            "       rcon_auth('', '123')\n" \
            "       rcon_auth(password: '123')\n"
    end
    data = []
    if name.nil? || name == ''
      data += Packer.pack_str(password)
    else # ddnet auth using name, password and some int?
      data += Packer.pack_str(name)
      data += Packer.pack_str(password)
      data += Packer.pack_int(1)
    end
    msg = NetChunk.create_header(vital: true, size: data.size + 1) +
          [pack_msg_id(NETMSG_RCON_AUTH, system: true)] +
          data
    @netbase.send_packet(msg)
  end

  def rcon(command)
    data = []
    data += Packer.pack_str(command)
    msg = NetChunk.create_header(vital: true, size: data.size + 1) +
          [pack_msg_id(NETMSG_RCON_CMD, system: true)] +
          data
    @netbase.send_packet(msg)
  end

  def send_msg_start_info
    data = []

    @start_info.each do |key, value|
      if value.instance_of?(String)
        data += Packer.pack_str(value)
      elsif value.instance_of?(Integer)
        data += Packer.pack_int(value)
      else
        puts "Error: invalid start info #{key}: #{value}"
        exit 1
      end
    end

    @netbase.send_packet(
      NetChunk.create_header(vital: true, size: data.size + 1) +
      [pack_msg_id(NETMSGTYPE_CL_STARTINFO, system: false)] +
      data
    )
  end

  def send_iam
    data = []
    # "i-am-teeworlds_network@chillerdragon.github.io"
    data += [0x99, 0xd8, 0x0f, 0x9d, 0x13, 0x25, 0x38, 0x12, 0xb1, 0x7b, 0x6e, 0xbd, 0x1b, 0x56, 0x99, 0x89]
    data += Packer.pack_int(TEEWORLDS_NETWORK_VERSION_NUMBER)
    data += Packer.pack_str("teeworlds_network=#{TEEWORLDS_NETWORK_VERSION} RUBY_VERSION=#{RUBY_VERSION} RUBY_ENGINE=#{RUBY_ENGINE}")
    data += Packer.pack_str("https://github.com/ChillerDragon/teeworlds_network")

    @netbase.send_packet(
      NetChunk.create_header(vital: true, size: data.size + 1) +
      [pack_msg_id(NETMSG_NULL, system: true)] +
      data
    )
  end

  def send_msg_ready
    @netbase.send_packet(
      NetChunk.create_header(vital: true, size: 1) +
      [pack_msg_id(NETMSG_READY, system: true)]
    )
  end

  def send_enter_game
    @netbase.send_packet(
      NetChunk.create_header(vital: true, size: 1) +
      [pack_msg_id(NETMSG_ENTERGAME, system: true)]
    )
  end

  def send_input(input = {})
    inp = {
      direction: input[:direction] || -1,
      target_x: input[:target_x] || 10,
      target_y: input[:target_y] || 10,
      jump: input[:jump] || rand(0..1),
      fire: input[:fire] || 0,
      hook: input[:hook] || 0,
      player_flags: input[:player_flags] || 0,
      wanted_weapon: input[:wanted_weapon] || 0,
      next_weapon: input[:next_weapon] || 0,
      prev_weapon: input[:prev_weapon] || 0
    }

    data = []
    data += Packer.pack_int(@game_client.ack_game_tick)
    data += Packer.pack_int(@game_client.pred_game_tick)
    data += Packer.pack_int(40) # magic size 40
    data += Packer.pack_int(inp[:direction])
    data += Packer.pack_int(inp[:target_x])
    data += Packer.pack_int(inp[:target_y])
    data += Packer.pack_int(inp[:jump])
    data += Packer.pack_int(inp[:fire])
    data += Packer.pack_int(inp[:hook])
    data += Packer.pack_int(inp[:player_flags])
    data += Packer.pack_int(inp[:wanted_weapon])
    data += Packer.pack_int(inp[:next_weapon])
    data += Packer.pack_int(inp[:prev_weapon])
    msg = NetChunk.create_header(vital: false, size: data.size + 1) +
          [pack_msg_id(NETMSG_INPUT, system: true)] +
          data
    @netbase.send_packet(msg)
  end

  private

  def on_msg_token(data)
    # TODO: add hook
    @token = bytes_to_str(data)
    @netbase.set_peer_token(@token)
    puts "Got token #{@token}"
    send_msg_connect
  end

  def on_msg_accept
    # TODO: add hook
    puts 'got accept. connection online'
    @state = NET_CONNSTATE_ONLINE
    send_info
  end

  def on_msg_close(data)
    @game_client.on_disconnect(data)
  end

  # CClient::ProcessConnlessPacket
  def on_ctrl_message(msg, data)
    case msg
    when NET_CTRLMSG_TOKEN then on_msg_token(data)
    when NET_CTRLMSG_ACCEPT then on_msg_accept
    when NET_CTRLMSG_CLOSE then on_msg_close(data)
    when NET_CTRLMSG_KEEPALIVE # silently ignore keepalive
    else
      puts "Uknown control message #{msg}"
      exit(1)
    end
  end

  def on_message(chunk)
    case chunk.msg
    when NETMSGTYPE_SV_READYTOENTER then @game_client.on_ready_to_enter(chunk)
    when NETMSGTYPE_SV_CLIENTINFO then @game_client.on_client_info(chunk)
    when NETMSGTYPE_SV_CLIENTDROP then @game_client.on_client_drop(chunk)
    when NETMSGTYPE_SV_EMOTICON then @game_client.on_emoticon(chunk)
    when NETMSGTYPE_SV_CHAT then @game_client.on_chat(chunk)
    else
      puts "todo non sys chunks. skipped msg: #{chunk.msg}" if @verbose
    end
  end

  def process_chunk(chunk)
    unless chunk.sys
      on_message(chunk)
      return
    end
    puts "proccess chunk with msg: #{chunk.msg}" if @verbose
    case chunk.msg
    when NETMSG_MAP_CHANGE
      @game_client.on_map_change(chunk)
    when NETMSG_SERVERINFO
      puts 'ignore server info for now'
    when NETMSG_CON_READY
      @game_client.on_connected
    when NETMSG_NULL
      # should we be in alert here?
    when NETMSG_RCON_LINE
      @game_client.on_rcon_line(chunk)
    when NETMSG_SNAP, NETMSG_SNAPSINGLE, NETMSG_SNAPEMPTY
      @game_client.on_snapshot(chunk)
    when NETMSG_INPUTTIMING
      @game_client.on_input_timing(chunk)
    when NETMSG_RCON_AUTH_ON
      @game_client.on_auth_on
    when NETMSG_RCON_AUTH_OFF
      @game_client.on_auth_off
    when NETMSG_RCON_CMD_ADD
      @game_client.on_rcon_cmd_add(chunk)
    when NETMSG_RCON_CMD_REM
      @game_client.on_rcon_cmd_rem(chunk)
    when NETMSG_MAPLIST_ENTRY_ADD
      @game_client.on_maplist_entry_add(chunk)
    when NETMSG_MAPLIST_ENTRY_REM
      @game_client.on_maplist_entry_rem(chunk)
    else
      puts "Unsupported system msg: #{chunk.msg}"
      p str_hex(chunk.full_raw)
      exit(1)
    end
  end

  def process_server_packet(packet)
    data = packet.payload
    if data.empty?
      puts 'Error: packet payload is empty'
      puts packet
      return
    end
    chunks = BigChungusTheChunkGetter.get_chunks(data)
    chunks.each do |chunk|
      if chunk.flags_vital
        if chunk.seq == (@netbase.ack + 1) % NET_MAX_SEQUENCE
          # in sequence
          @netbase.ack = (@netbase.ack + 1) % NET_MAX_SEQUENCE
        else
          puts 'warning: got chunk out of sequence! ' \
               "seq=#{chunk.seq} expected_seq=#{(@netbase.ack + 1) % NET_MAX_SEQUENCE}"
          if seq_in_backroom?(chunk.seq, @netbase.ack)
            puts '         dropping known chunk ...'
            next
          end
          # TODO: request resend
          puts '         REQUESTING RESEND NOT IMPLEMENTED'
        end
      end
      process_chunk(chunk)
    end
  end

  def tick
    # puts "tick"
    begin
      pck = @s.recvfrom_nonblock(1400)
    rescue Errno::ECONNREFUSED
      puts 'connection problems ...'
      pck = nil
    rescue IO::EAGAINWaitReadable
      pck = nil
    rescue IO::EWOULDBLOCKWaitReadable # windows
      pck = nil
    end
    if pck.nil? && @token.nil?
      @wait_for_token ||= 0
      @wait_for_token += 1
      if @wait_for_token > 6
        @token = nil
        send_ctrl_with_token
        puts 'retrying connection ...'
      end
    end
    @game_client.on_tick
    return unless pck

    data = pck.first

    packet = Packet.new(data, '<')
    puts packet if @verbose

    # process connless packets data
    if packet.flags_control
      msg = data[PACKET_HEADER_SIZE].unpack1('C*')
      on_ctrl_message(msg, data[(PACKET_HEADER_SIZE + 1)..])
    else # process non-connless packets
      process_server_packet(packet)
    end

    send_ctrl_keepalive if (@ticks % 8).zero?
    if @game_client.ack_game_tick.positive?
      now = Time.now
      @@last_pred ||= now
      diff = now - @@last_pred
      # @Swarfey does js setInterval(20) in his lib
      # not sure if it makes sense to do a diff > 0.2 here then xd
      @game_client.pred_game_tick += 1 if diff > 0.2
    end

    @ticks += 1
    send_input if (@ticks % 20).zero?
  end

  def connection_loop
    until @signal_disconnect
      tick
      # TODO: proper tick speed sleep
      sleep 0.001
    end
    @thread_running = false
    @signal_disconnect = false
  end
end
