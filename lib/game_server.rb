# frozen_string_literal: true

require_relative 'context'
require_relative 'models/map'
require_relative 'models/chat_message'
require_relative 'messages/game_info'
require_relative 'messages/server_info'
require_relative 'messages/server_settings'
require_relative 'messages/start_info'
require_relative 'messages/cl_say'
require_relative 'messages/cl_emoticon'
require_relative 'messages/cl_info'
require_relative 'messages/cl_input'
require_relative 'messages/client_info'

class GameServer
  attr_accessor :pred_game_tick, :ack_game_tick, :map

  def initialize(server)
    @server = server
    @config = server.config
    @map_path = nil
    @ack_game_tick = -1
    @pred_game_tick = 0
    @map = Map.new(
      name: 'dm1',
      crc: '98a0a4c50c', # decimal 64548818
      size: 6793,
      sha256: '491af17a510214506270904f147a4c30ae0a85b91bb854395bef8c397fc078c3'
    )
  end

  def load_map
    puts "loading map '#{@config.sv_map}' ..."
    map_path = nil
    if File.exist? "data/#{@config.sv_map}.map"
      map_path = "data/#{@config.sv_map}.map"
    elsif File.exist? "data/maps/#{@config.sv_map}.map"
      map_path = "data/maps/#{@config.sv_map}.map"
    elsif File.exist? "maps/#{@config.sv_map}.map"
      map_path = "maps/#{@config.sv_map}.map"
    elsif File.exist? "#{Dir.home}/.teeworlds/maps/#{@config.sv_map}.map"
      map_path = "#{Dir.home}/.teeworlds/maps/#{@config.sv_map}.map"
    end

    if map_path.nil?
      puts "map not found '#{@config.sv_map}'"
      # TODO: this should error when the feature is done
      # exit 1
    else
      puts "found at #{map_path}"
      @map_path = map_path
    end
  end

  ##
  # call_hook
  #
  # @param: hook_sym [Symbol] name of the symbol to call
  # @param: context [Context] context object to pass on data
  # @param: optional [Any] optional 2nd parameter passed to the callback
  def call_hook(hook_sym, context, optional = nil)
    @server.hooks[hook_sym].each do |hook|
      hook.call(context, optional)
      context.verify
      return nil if context.canceld?
    end
    context
  end

  def on_emoticon(chunk, packet)
    msg = ClEmoticon.new(chunk.data[1..])
    return if call_hook(:emote, Context.new(msg, chunk:, packet:)).nil?

    @server.send_emoticon(packet.client.player.id, msg.emoticon)
  end

  def on_info(chunk, packet)
    msg = ClInfo.new(chunk.data[1..])

    return if call_hook(:info, Context.new(msg, chunk:, packet:)).nil?

    # TODO: check version and password
    puts "vers=#{msg.net_version} vers=#{msg.client_version} pass=#{msg.password}"
    @server.send_map(packet.client)
  end

  def on_ready(_chunk, packet)
    # vanilla server sends 3 chunks here usually
    #  - motd
    #  - server settings
    #  - ready
    #
    return if call_hook(:ready, Context.new(nil, chunk: nil, packet:)).nil?

    @server.send_server_settings(packet.client, ServerSettings.new.to_a)
    @server.send_ready(packet.client)
  end

  def on_start_info(chunk, packet)
    # vanilla server sends 3 chunks here usually
    #  - vote clear options
    #  - tune params
    #  - ready to enter
    #
    # We only send ready to enter for now
    info = StartInfo.new(chunk.data[1..])
    return if call_hook(:start_info, Context.new(info, chunk: nil, packet:)).nil?

    packet.client.player.set_start_info(info)
    info_str = info.to_s
    puts "got start info: #{info_str}" if @verbose
    @server.send_ready_to_enter(packet.client)
  end

  def on_say(chunk, packet)
    say = ClSay.new(chunk.data[1..])
    author = packet.client.player
    msg = ChatMesage.new(say.to_h.merge(client_id: author.id, author:))
    context = Context.new(say, chunk:)
    return if call_hook(:chat, context, msg).nil?

    puts msg
  end

  # https://chillerdragon.github.io/teeworlds-protocol/07/game_messages.html#NETMSGTYPE_SV_CLIENTINFO
  # send infos about currently connected clients to the newly joined client
  # send info of the newly joined client to all currently connected clients
  #
  # @param client [Client] newly joined client
  def send_client_infos(client)
    client_info = ClientInfo.new(client_id: client.id, local: 1)
    @server.send_client_info(client, client_info)
  end

  def on_enter_game(_chunk, packet)
    # vanilla server responds to enter game with two packets
    # first:
    #  - server info
    # second:
    #  - game info
    #  - client info
    #  - snap single
    return if call_hook(:enter_game, Context.new(nil, chunk: nil, packet:)).nil?

    packet.client.in_game = true
    @server.send_server_info(packet.client, ServerInfo.new.to_a)
    send_client_infos(packet.client)
    @server.send_game_info(packet.client, GameInfo.new.to_a)

    puts "'#{packet.client.player.name}' joined the game"
  end

  def on_rcon_cmd(chunk, packet)
    u = Unpacker.new(chunk.data[1..])
    command = u.get_string
    return if call_hook(:rcon_cmd, Context.new(nil, chunk:, packet:, command:)).nil?
    return unless packet.client.authed?

    puts "[server] ClientID=#{packet.client.player.id} rcon='#{command}'"
    if command == 'shutdown'
      @server.shutdown!('Server shutdown')
    else
      puts "[console] No such command: #{command}:"
    end
  end

  def on_rcon_auth(chunk, packet)
    u = Unpacker.new(chunk.data[1..])
    password = u.get_string
    return if call_hook(:rcon_auth, Context.new(nil, chunk:, packet:, password:)).nil?

    # TODO: we accept any password lol
    puts "[server] ClientID=#{packet.client.player.id} addr=#{packet.client.addr} authed (admin)"
    packet.client.authed = true
    @server.send_rcon_auth_on(packet.client)
  end

  def on_input(chunk, packet)
    # vanilla server responds to input with 2 chunks
    #  - input_timing
    #  - snap (empty)

    msg = ClInput.new(chunk.data[1..])
    return if call_hook(:input, Context.new(msg, chunk:, packet:)).nil?

    dir = msg.direction
    puts "#{packet.client.player.id} tried to move #{dir}" unless dir.zero?
  end

  def on_client_drop(client, reason = nil)
    reason = reason.nil? ? '' : " (#{reason})"
    return if call_hook(:client_drop, Context.new(nil, client:, reason:)).nil?

    puts "'#{client.player.name}' left the game#{reason}"
  end

  def on_shutdown
    return if call_hook(:shutdown, Context.new(nil)).nil?

    puts '[gameserver] disconnecting all clients ...'
    @server.clients.each_value do |client|
      @server.send_ctrl_close(client, @server.shutdown_reason)
    end
    puts '[gameserver] shutting down ...'
  end

  def on_tick
    return if call_hook(:tick, Context.new(nil)).nil?

    now = Time.now
    timeout_ids = []
    @server.clients.each do |id, client|
      diff = now - client.last_recv_time
      timeout_ids.push(id) if diff > 10
    end

    timeout_ids.each do |id|
      @server.drop_client(@server.clients[id], 'Timeout')
    end
  end
end
