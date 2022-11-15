# frozen_string_literal: true

require_relative 'models/player'
require_relative 'models/chat_message'
require_relative 'models/input_timing'
require_relative 'models/sv_client_drop'
require_relative 'packer'
require_relative 'context'

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
      return nil if context.cancled?
    end
    context
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
    @players[player.id] = player
  end

  def on_input_timing(chunk)
    todo_rename_this = InputTiming.new(chunk.data[1..])
    context = Context.new(todo_rename_this, chunk:)
    call_hook(:input_timing, context)
  end

  def on_client_drop(chunk)
    todo_rename_this = SvClientDrop.new(chunk.data[1..])
    context = Context.new(
      nil,
      player: @players[todo_rename_this.client_id],
      chunk:,
      client_id: todo_rename_this.client_id,
      reason: todo_rename_this.reason,
      silent: todo_rename_this.silent?
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

  def on_disconnect
    call_hook(:disconnect, Context.new(nil))
  end

  def on_rcon_line(chunk)
    u = Unpacker.new(chunk.data[1..])
    context = Context.new(
      nil,
      line: u.get_string
    )
    call_hook(:rcon_line, context)
  end

  def on_snapshot(chunk)
    u = Unpacker.new(chunk.data)
    u.get_int
    # msg = u.get_int
    # msg >>= 1

    # num_parts = 1
    # part = 0
    game_tick = u.get_int
    # delta_tick = u.get_int
    # part_size = 0
    # crc = 0
    # complete_size = 0
    # data = nil

    # TODO: state check

    # if msg == NETMSG_SNAP
    #   num_parts = u.get_int
    #   part = u.get_int
    # end

    # unless msg == NETMSG_SNAPEMPTY
    #   crc = u.get_int
    #   part_size = u.get_int
    # end

    # TODO: add get_raw(size)
    # data = u.get_raw

    # ack every snapshot no matter how broken
    @ack_game_tick = game_tick
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
