# frozen_string_literal: true

require 'socket'

require_relative 'string'
require_relative 'array'
require_relative 'bytes'
require_relative 'network'
require_relative 'packet'
require_relative 'chunk'
require_relative 'net_base'
require_relative 'models/net_addr'
require_relative 'packer'
require_relative 'game_server'
require_relative 'message'
require_relative 'models/token'

class Client
  attr_accessor :id, :addr, :vital_sent, :last_recv_time, :token, :player, :in_game
  attr_reader :ack

  def initialize(attr = {})
    @id = attr[:id]
    @addr = attr[:addr]
    @vital_sent = 0
    @ack = 0
    @in_game = false
    @last_recv_time = Time.now
    @player = Player.new(
      id: @id,
      local: 0,
      team: 0,
      name: '(connecting)',
      clan: '',
      country: -1
    )
    @token = attr[:token]
    SecurityToken.validate(@token)
  end

  def in_game?
    @in_game
  end

  def bump_ack
    @ack = (@ack + 1) % NET_MAX_SEQUENCE
  end

  # TODO: use or remove
  #       not sure if its cool
  #       one can make vital_sent read only
  #       and then the seq reader increments it
  #       so everytime a header is created
  #       the chunk builder just calls
  #       seq = client.seq
  def seq
    @vital_sent + 1
  end
end

class TeeworldsServer
  attr_accessor :clients

  def initialize(options = {})
    @verbose = options[:verbose] || false
    @ip = '127.0.0.1'
    @port = 8303
    @game_server = GameServer.new(self)
    @clients = {}
    @current_game_tick = 0
    @last_snap_time = Time.now
  end

  def run(ip, port)
    @server_token = (1..4).to_a.map { |_| rand(0..255) }
    @server_token = @server_token.map { |b| b.to_s(16).rjust(2, '0') }.join
    puts "server token #{@server_token}"
    @netbase = NetBase.new(verbose: @verbose)
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
      #       replace by blocking network read
      #       m_NetServer
      #         .Wait(
      #         clamp(
      #         int((
      #         TickStartTime(
      #         m_CurrentGameTick+1)-time_get()
      #         )*1000/time_freq()),
      #         1,
      #         1000/SERVER_TICK_SPEED/2));
      sleep 0.001
    end
  end

  def on_message(chunk, packet)
    puts "got game chunk: #{chunk}"
    case chunk.msg
    when NETMSGTYPE_CL_STARTINFO then @game_server.on_start_info(chunk, packet)
    when NETMSGTYPE_CL_SAY then @game_server.on_say(chunk, packet)
    when NETMSGTYPE_CL_EMOTICON then @game_server.on_emoticon(chunk, packet)
    else
      puts "Unsupported game msg: #{chunk.msg}"
      exit(1)
    end
  end

  def process_chunk(chunk, packet)
    unless chunk.sys
      on_message(chunk, packet)
      return
    end
    puts "proccess chunk with msg: #{chunk.msg}" if @verbose
    case chunk.msg
    when NETMSG_INFO
      @game_server.on_info(chunk, packet)
    when NETMSG_READY
      @game_server.on_ready(chunk, packet)
    when NETMSG_ENTERGAME
      @game_server.on_enter_game(chunk, packet)
    when NETMSG_INPUT
      @game_server.on_input(chunk, packet)
    when NETMSG_RCON_CMD
      @game_server.on_rcon_cmd(chunk, packet)
    else
      puts "Unsupported system msg: #{chunk.msg}"
      exit(1)
    end
  end

  def on_client_packet(packet)
    client = packet.client
    if client.nil?
      # TODO: turn this into a silent return
      #       otherwise bad actors can easily trigger this
      #       with handcrafted packets
      puts 'Error: got client packet from unknown client'
      exit 1
    end
    chunks = BigChungusTheChunkGetter.get_chunks(packet.payload)
    chunks.each do |chunk|
      if chunk.flags_vital && !chunk.flags_resend
        packet.client.bump_ack
        puts "got ack: #{packet.client.ack}" if @verbose
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

  def send_ctrl_close(client, reason)
    # when clients disconnect
    # during the connection process
    # we do not care
    return if client.nil?

    msg = [NET_CTRLMSG_CLOSE]
    msg += Packer.pack_str(reason) unless reason.nil?
    @netbase.set_peer_token(client.token)
    @netbase.send_packet(msg, chunks: 0, control: true, client:)
    # @netbase.set_peer_token(@server_token)
  end

  def send_ctrl_with_token(addr, token)
    msg = [NET_CTRLMSG_TOKEN] + str_bytes(@server_token)
    @netbase.set_peer_token(token)
    @netbase.send_packet(msg, chunks: 0, control: true, addr:)
    # @netbase.set_peer_token(@server_token)
  end

  def send_map(client)
    data = []
    data += Packer.pack_str(@game_server.map.name)
    data += @game_server.map.crc_arr # poor mans pack_raw()
    data += Packer.pack_int(@game_server.map.size)
    data += Packer.pack_int(8) # chunk num?
    data += Packer.pack_int(MAP_CHUNK_SIZE)
    data += @game_server.map.sha256_arr # poor mans pack_raw()
    msg = NetChunk.create_header(vital: true, size: data.size + 1, client:) +
          [pack_msg_id(NETMSG_MAP_CHANGE, system: true)] +
          data
    @netbase.send_packet(msg, chunks: 1, client:)
  end

  def send_ready(client)
    msg = NetChunk.create_header(vital: true, size: 1, client:) +
          [pack_msg_id(NETMSG_CON_READY, system: true)]
    @netbase.send_packet(msg, chunks: 1, client:)
  end

  def send_ready_to_enter(client)
    msg = NetChunk.create_header(vital: true, size: 1, client:) +
          [pack_msg_id(NETMSGTYPE_SV_READYTOENTER, system: false)]
    @netbase.send_packet(msg, chunks: 1, client:)
  end

  def send_server_settings(client, server_settings)
    msg = NetChunk.create_header(vital: true, size: 1 + server_settings.size, client:) +
          [pack_msg_id(NETMSGTYPE_SV_SERVERSETTINGS, system: false)] +
          server_settings
    @netbase.send_packet(msg, chunks: 1, client:)
  end

  def send_server_info(client, server_info)
    msg = NetChunk.create_header(vital: true, size: 1 + server_info.size, client:) +
          [pack_msg_id(NETMSG_SERVERINFO, system: true)] +
          server_info
    @netbase.send_packet(msg, chunks: 1, client:)
  end

  def send_game_info(client, data)
    msg = NetChunk.create_header(vital: true, size: 1 + data.size, client:) +
          [pack_msg_id(NETMSGTYPE_SV_GAMEINFO, system: false)] +
          data
    @netbase.send_packet(msg, chunks: 1, client:)
  end

  def on_ctrl_token(packet)
    u = Unpacker.new(packet.payload[1..])
    token = u.get_raw(4)
    token_str = token.map { |b| b.to_s(16).rjust(2, '0') }.join
    puts "got token #{token_str}"
    send_ctrl_with_token(packet.addr, token_str)
  end

  def on_ctrl_keep_alive(packet)
    puts "Got keep alive from #{packet.addr}" if @verbose
  end

  def on_ctrl_close(packet)
    reason = nil
    if packet.payload[2]
      u = Unpacker.new(packet.payload[1..])
      reason = u.get_string
    end
    drop_client(packet.client, reason)
  end

  def drop_client(client, reason = nil)
    send_ctrl_close(client, reason)
    return if client.nil?

    @game_server.on_client_drop(client, reason)
    @clients.delete(client.id)
  end

  def on_ctrl_connect(packet)
    id = get_next_client_id
    if id == -1
      puts 'server full drop packet. TODO: tell the client'
      return
    end
    token = bytes_to_str(packet.payload[1..4])
    puts "got connection, sending accept (client token: #{token})"
    client = Client.new(id:, addr: packet.addr, token:)
    @clients[id] = client
    @netbase.send_packet([NET_CTRLMSG_ACCEPT], chunks: 0, control: true, client:)
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

  def tick_start_time(tick)
    # TODO: implement this C++ code
    #       m_GameStartTime + (time_freq()*Tick)/SERVER_TICK_SPEED;
  end

  def do_snapshot
    delta_tick = -1
    # DeltaTick = m_aClients[i].m_LastAckedSnapshot;
    data = []
    data += Packer.pack_int(@current_game_tick)
    data += Packer.pack_int(@current_game_tick - delta_tick)
    msg_snap_empty = NetChunk.create_header(vital: false, size: data.size + 1) +
                     [pack_msg_id(NETMSG_SNAPEMPTY, system: true)] +
                     data
    @clients.each do |_id, client|
      next unless client.in_game?

      @netbase.send_packet(msg_snap_empty, chunks: 1, client:)
    end
  end

  def get_player_by_id(id)
    @clients[id]&.player
  end

  def tick
    unless @clients.empty?
      now = Time.now
      diff = now - @last_snap_time
      # TODO: replace snaps every second by something more correct
      if diff > 1
        @current_game_tick += 1
        do_snapshot
      end
      @game_server.on_tick
    end

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

      client.last_recv_time = Time.now
      packet.client_id = id
      packet.client = client
    end

    puts packet.to_s if @verbose
    on_packet(packet)
  end
end
