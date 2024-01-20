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

class GameServer
  attr_accessor :pred_game_tick, :ack_game_tick, :map

  def initialize(server)
    @server = server
    @ack_game_tick = -1
    @pred_game_tick = 0
    @map = Map.new(
      name: 'dm1',
      crc: '98a0a4c50c', # decimal 64548818
      size: 6793,
      sha256: '491af17a510214506270904f147a4c30ae0a85b91bb854395bef8c397fc078c3'
    )
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

  def on_emoticon(chunk, _packet)
    message = ClEmoticon.new(chunk.data[1..])
    p message
  end

  def on_info(chunk, packet)
    u = Unpacker.new(chunk.data[1..])
    net_version = u.get_string
    password = u.get_string
    client_version = u.get_int
    puts "vers=#{net_version} vers=#{client_version} pass=#{password}"

    # TODO: check version and password

    @server.send_map(packet.client)
  end

  def on_ready(_chunk, packet)
    # vanilla server sends 3 chunks here usually
    #  - motd
    #  - server settings
    #  - ready
    #
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

  def on_enter_game(_chunk, packet)
    # vanilla server responds to enter game with two packets
    # first:
    #  - server info
    # second:
    #  - game info
    #  - client info
    #  - snap single
    packet.client.in_game = true
    @server.send_server_info(packet.client, ServerInfo.new.to_a)
    @server.send_game_info(packet.client, GameInfo.new.to_a)

    puts "'#{packet.client.player.name}' joined the game"
  end

  def on_rcon_cmd(chunk, _packet)
    u = Unpacker.new(chunk.data[1..])
    command = u.get_string
    return if call_hook(:rcon_cmd, Context.new(nil, chunk:, packet:, command:)).nil?
    return unless packet.client.authed?

    puts "[server] ClientID=#{packet.client.player.id} rcon='#{command}'"
    if command == 'shutdown'
      @server.shutdown!
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
  end

  def on_input(chunk, packet)
    # vanilla server responds to input with 2 chunks
    #  - input_timing
    #  - snap (empty)

    # we do nothing for now
    # TODO: do something
  end

  def on_client_drop(client, reason = nil)
    reason = reason.nil? ? '' : " (#{reason})"
    puts "'#{client.player.name}' left the game#{reason}"
  end

  def on_shutdown
    return if call_hook(:shutdown, Context.new(nil)).nil?

    puts '[gameserver] shutting down ...'
  end

  def on_tick
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
