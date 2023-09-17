# frozen_string_literal: true

require_relative 'models/player'
require_relative 'models/chat_message'
require_relative 'messages/input_timing'
require_relative 'messages/rcon_line'
require_relative 'messages/sv_client_drop'
require_relative 'messages/rcon_cmd_add'
require_relative 'messages/rcon_cmd_rem'
require_relative 'messages/maplist_entry_add'
require_relative 'messages/maplist_entry_rem'
require_relative 'packer'
require_relative 'context'
require_relative 'snapshot/unpacker'

class GameClient
  attr_accessor :players, :pred_game_tick, :ack_game_tick

  def initialize(client)
    @client = client
    @players = {}
    @ack_game_tick = -1
    @pred_game_tick = 0
  end

  ##
  # call_hook
  #
  # @param: hook_sym [Symbol] name of the symbol to call
  # @param: context [Context] context object to pass on data
  # @param: optional [Any] optional 2nd parameter passed to the callback
  def call_hook(hook_sym, context, optional = nil)
    @client.hooks[hook_sym].each do |hook|
      hook.call(context, optional)
      context.verify
      return nil if context.canceld?
    end
    context
  end

  def on_tick
    call_hook(:tick, nil)
  end

  def on_auth_on
    return if call_hook(:auth_on, Context.new(nil)).nil?

    @client.rcon_authed = true
    puts 'rcon logged in'
  end

  def on_auth_off
    return if call_hook(:auth_off, Context.new(nil)).nil?

    @client.rcon_authed = false
    puts 'rcon logged out'
  end

  def on_rcon_cmd_add(chunk)
    message = RconCmdAdd.new(chunk.data[1..])
    context = Context.new(message)
    call_hook(:rcon_cmd_add, context)
  end

  def on_rcon_cmd_rem(chunk)
    message = RconCmdRem.new(chunk.data[1..])
    context = Context.new(message)
    call_hook(:rcon_cmd_rem, context)
  end

  def on_maplist_entry_add(chunk)
    message = MaplistEntryAdd.new(chunk.data[1..])
    context = Context.new(message)
    call_hook(:maplist_entry_add, context)
  end

  def on_maplist_entry_rem(chunk)
    message = MaplistEntryRem.new(chunk.data[1..])
    context = Context.new(message)
    call_hook(:maplist_entry_rem, context)
  end

  def on_client_info(chunk)
    # puts "Got playerinfo flags: #{chunk.flags}"
    u = Unpacker.new(chunk.data[1..])
    player = Player.new(
      id: u.get_int,
      local: u.get_int,
      team: u.get_int,
      name: u.get_string,
      clan: u.get_string,
      country: u.get_int
    )
    # skinparts and the silent flag
    # are currently ignored

    context = Context.new(
      nil,
      player:,
      chunk:
    )
    return if call_hook(:client_info, context).nil?

    player = context.data[:player]
    if player.local?
      @client.local_client_id = player.id
      puts "Our client id is #{@client.local_client_id}"
    end
    @players[player.id] = player
  end

  def on_input_timing(chunk)
    message = InputTiming.new(chunk.data[1..])
    context = Context.new(message, chunk:)
    call_hook(:input_timing, context)
  end

  def on_client_drop(chunk)
    message = SvClientDrop.new(chunk.data[1..])
    context = Context.new(
      nil,
      player: @players[message.client_id],
      chunk:,
      client_id: message.client_id,
      reason: message.reason,
      silent: message.silent?
    )
    return if call_hook(:client_drop, context).nil?

    @players.delete(context.data[:client_id])
  end

  def on_ready_to_enter(_chunk)
    @client.send_enter_game
  end

  def on_connected
    context = Context.new(nil)
    return if call_hook(:connected, context).nil?

    @client.send_msg_start_info
  end

  def on_disconnect(data)
    context = Context.new(nil, reason: data)
    return if call_hook(:disconnect, context).nil?

    puts "got disconnect. reason='#{context.data[:reason]}'"
  end

  def on_rcon_line(chunk)
    message = RconLine.new(chunk.data[1..])
    context = Context.new(message)
    return if call_hook(:rcon_line, context).nil?

    puts "[rcon] #{context.message.command}"
  end

  def on_snapshot(chunk)
    u = SnapshotUnpacker.new(@client)
    snapshot = u.snap_single(chunk)

    return if snapshot.nil?

    context = Context.new(nil, chunk:)
    return if call_hook(:snapshot, context, snapshot).nil?

    # ack every snapshot no matter how broken
    @ack_game_tick = snapshot.game_tick
    return unless (@pred_game_tick - @ack_game_tick).abs > 10

    @pred_game_tick = @ack_game_tick + 1
  end

  def on_emoticon(chunk); end

  def on_map_change(chunk)
    context = Context.new(nil, chunk:)
    return if call_hook(:map_change, context).nil?

    # ignore mapdownload at all times
    # and claim to have the map
    @client.send_msg_ready
  end

  def on_chat(chunk)
    u = Unpacker.new(chunk.data[1..])
    data = {
      mode: u.get_int,
      client_id: u.get_int,
      target_id: u.get_int,
      message: u.get_string
    }
    data[:author] = @players[data[:client_id]]
    msg = ChatMesage.new(data)

    context = Context.new(nil, chunk:)
    call_hook(:chat, context, msg)
  end
end
