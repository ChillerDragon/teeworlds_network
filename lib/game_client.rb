# frozen_string_literal: true

require_relative 'models/player'
require_relative 'models/chat_message'
require_relative 'messages/input_timing'
require_relative 'messages/sv_client_drop'
require_relative 'messages/rcon_cmd_add'
require_relative 'messages/rcon_cmd_rem'
require_relative 'messages/maplist_entry_add'
require_relative 'messages/maplist_entry_rem'
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
      return nil if context.canceld?
    end
    context
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
    todo_rename_this = RconCmdAdd.new(chunk.data[1..])
    context = Context.new(todo_rename_this)
    return if call_hook(:rcon_cmd_add, context).nil?

    p context.todo_rename_this
  end

  def on_rcon_cmd_rem(chunk)
    todo_rename_this = RconCmdRem.new(chunk.data[1..])
    context = Context.new(todo_rename_this)
    return if call_hook(:rcon_cmd_rem, context).nil?

    p context.todo_rename_this
  end

  def on_maplist_entry_add(chunk)
    todo_rename_this = MaplistEntryAdd.new(chunk.data[1..])
    context = Context.new(todo_rename_this)
    return if call_hook(:maplist_entry_add, context).nil?

    p context.todo_rename_this
  end

  def on_maplist_entry_rem(chunk)
    todo_rename_this = MaplistEntryRem.new(chunk.data[1..])
    context = Context.new(todo_rename_this)
    return if call_hook(:maplist_entry_rem, context).nil?

    p context.todo_rename_this
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
    msg_id = u.get_int
    msg_id >>= 1

    num_parts = 1
    part = 0
    game_tick = u.get_int
    delta_tick = u.get_int
    part_size = 0
    crc = 0
    # complete_size = 0
    # data = nil

    chunk_num = 0

    # TODO: state check

    if msg_id == NETMSG_SNAP
      num_parts = u.get_int
      part = u.get_int
    end

    unless msg_id == NETMSG_SNAPEMPTY
      crc = u.get_int
      part_size = u.get_int
      chunk_num = u.get_int
    end

    snap_name = 'SNAP_INVALID'
    case msg_id
    when NETMSG_SNAP then snap_name = 'NETMSG_SNAP'
    when NETMSG_SNAPSINGLE then snap_name = 'NETMSG_SNAPSINGLE'
    when NETMSG_SNAPEMPTY then snap_name = 'NETMSG_SNAPEMPTY'
    end

    return unless msg_id == NETMSG_SNAPSINGLE

    puts ">>> snap #{snap_name} (#{msg_id})"
    puts "  id=#{msg_id} game_tick=#{game_tick} delta_tick=#{delta_tick}"
    puts "  num_parts=#{num_parts} part=#{part} crc=#{crc} part_size=#{part_size}"
    puts "  chunk_num=#{chunk_num}"
    puts "\n  header:"

    header = []
    notes = []
    u.parsed.each_with_index do |parsed, index|
      color = (index % 2).zero? ? :green : :pink
      txt = "#{parsed[:type]} #{parsed[:value]}"
      txt += " >> 1 = #{parsed[:value] >> 1}" if header.empty?
      notes.push([color, parsed[:pos], parsed[:len], txt])
      header += parsed[:raw]
    end

    hexdump_lines(header.pack('C*'), 1, notes, legend: :inline).each do |hex|
      puts "  #{hex}"
    end

    puts "\n  payload:"
    data = u.get_raw
    # [:green, 0, 4, 'who dis?']
    notes = []
    # data.groups_of(4).each_with_index do |item, index|
    #   # reverse for little endian
    #   type = item[0...2].reverse.map { |b| b.to_s(2).rjust(8, '0') }.join.to_i(2)
    #   notes.push([:green, index * 4, 2, "type=#{type}"])
    #   next unless item.length == 4

    #   # reverse for little endian
    #   id = item[2...4].reverse.map { |b| b.to_s(2).rjust(8, '0') }.join.to_i(2)
    #   notes.push([:yellow, index * 4 + 2, 2, "id=#{id}"])
    # end

    @sizes = [
      0,
      10,
      6,
      5,
      3,
      3,
      3,
      2,
      4,
      15,
      22,
      3,
      4,
      58,
      5,
      32,
      2,
      2,
      2,
      2,
      3,
      3,
      5
    ]

    @snap_items = [
      { name: 'placeholder', size: 0 },
      { name: 'obj_player_input', size: 10 },
      { name: 'obj_projectile', size: 6 },
      { name: 'obj_laser', size: 5 },
      { name: 'obj_pickup', size: 3 },
      { name: 'obj_flag', size: 3 },
      { name: 'obj_game_data', size: 3 },
      { name: 'obj_game_data_team', size: 2 },
      { name: 'obj_game_data_flag', size: 4 },
      { name: 'obj_character_core', size: 15 },
      { name: 'obj_character', size: 22 },
      { name: 'obj_player_info', size: 3 },
      { name: 'obj_spectator_info', size: 4 },
      { name: 'obj_client_info', size: 58 },
      { name: 'obj_game_info', size: 5 },
      { name: 'obj_tune_params', size: 32 },
      { name: 'event_common', size: 2 },
      { name: 'event_explosion', size: 2 },
      { name: 'event_spawn', size: 2 },
      { name: 'event_hammerhit', size: 2 },
      { name: 'event_death', size: 3 },
      { name: 'event_sound_world', size: 3 },
      { name: 'event_damage', size: 5 }
    ]

    skip = 0
    (0...data.size).each do |i|
      skip -= 1
      next unless skip.negative?

      # reverse for little endian
      id = data[i...(i + 2)].reverse.map { |b| b.to_s(2).rjust(8, '0') }.join.to_i(2)

      next if data[i + 4].nil?

      type = data[(i + 2)...(i + 4)].reverse.map { |b| b.to_s(2).rjust(8, '0') }.join.to_i(2)
      size = @sizes[type]
      # p "id=#{id} type=#{type}"

      next if size.nil?

      # size *= 4

      notes.push([:green, i, 2, "id=#{id}"])
      notes.push([:pink, i + 2, 2, "type=#{type} (#{@snap_items[type][:name]} size: #{size})"])
      notes.push([:yellow, i + 4, size, 'data'])
      skip += 3 + size

      # next
      # next unless item.length == 4

      # # reverse for little endian
      # id = item[2...4].reverse.map { |b| b.to_s(2).rjust(8, '0') }.join.to_i(2)
      # notes.push([:yellow, (index * 4) + 2, 2, "id=#{id}"])
    end

    hexdump_lines(data.pack('C*'), 1, notes, legend: :inline).each do |hex|
      puts "  #{hex}"
    end

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
