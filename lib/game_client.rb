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

    # TODO: state check

    if msg_id == NETMSG_SNAP
      num_parts = u.get_int
      part = u.get_int
    end

    unless msg_id == NETMSG_SNAPEMPTY
      crc = u.get_int
      part_size = u.get_int
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
      { name: 'obj_game_data', size: 3, fields: [
        { type: 'int', name: 'start_tick' },
        { type: 'int', name: 'flags' },
        { type: 'int', name: 'end_tick' }
      ] },
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

    data = u.get_raw

    # tw decompresses all bytes at once
    # and pads it with zeros to get the 4 byte aligned ints
    # we just grab one int at a time cuz yolo
    u = Unpacker.new(data)
    num_removed_items = u.get_int
    p = u.parsed.last
    notes.push([:red, p[:pos], p[:len], "removed_items=#{num_removed_items}"])

    num_item_deltas = u.get_int
    p = u.parsed.last
    notes.push([:blue, p[:pos], p[:len], "num_item_deltas=#{num_item_deltas}"])

    zero = u.get_int
    p = u.parsed.last
    notes.push([:cyan, p[:pos], p[:len], "_zero=#{zero}"])

    (0...num_removed_items).each do |i|
      deleted = u.get_int
      notes.push([:red, p[:pos], p[:len], "del[#{i}]=#{deleted}"])
    end

    item_delta = u.get_int
    while item_delta
      # item_bits = item_delta.to_s(2).rjust(32, '0')
      item_type = item_delta
      # item_id_bits = item_bits[0...16]
      # item_type_bits = item_bits[16..]
      # item_id = item_id_bits.to_i(2)
      # item_type = item_type_bits.to_i(2)
      item_meta = @snap_items[item_type]
      item_name = item_meta[:name]
      #   { name: 'obj_game_data', size: 3, fields: [
      #     { type: 'int', name: 'start_tick' },

      p = u.parsed.last
      notes.push([:green, p[:pos], p[:len], "type = #{item_type} #{item_name}"])

      item_id = u.get_int
      p = u.parsed.last
      notes.push([:cyan, p[:pos], p[:len], "id=#{item_id}"])

      size = item_meta[:size]
      (0...size).each do |i|
        val = u.get_int
        p = u.parsed.last
        color = (i % 2).zero? ? :yellow : :pink
        fields = item_meta[:fields]
        desc = ''
        desc = fields[i][:name] unless fields.nil? || fields[i].nil?
        notes.push([color, p[:pos], p[:len], "data[#{i}]=#{val} #{desc}"])
      end
      item_delta = u.get_int
    end

    # skip = 0
    # ((3 * 4)...data.size).each do |i|
    #   skip -= 1
    #   unless skip.negative?
    #     # puts "skipped i=#{i} hex=#{str_hex([data[i]].pack('C*'))} skips_left=#{skip}"
    #     next
    #   end

    #   # reverse for little endian
    #   id = data[i...(i + 2)].reverse.map { |b| b.to_s(2).rjust(8, '0') }.join.to_i(2)

    #   if data[i + 4].nil? && i > 2
    #     puts "Error: unexpected end of data at i=#{i + 4} data_size=#{data.size}"
    #     next
    #   end

    #   type = data[(i + 2)...(i + 4)].reverse.map { |b| b.to_s(2).rjust(8, '0') }.join.to_i(2)
    #   size = @sizes[type]
    #   # p "id=#{id} type=#{type}"

    #   if size.nil? && i > 2
    #     puts "Error: could not get size for type=#{type} -> skip byte"
    #     next
    #   end

    #   size *= 4

    #   meta = @snap_items[type]

    #   notes.push([:green, i, 2, "id=#{id}"])
    #   notes.push([:pink, i + 2, 2, "type=#{type} (#{meta[:name]} size: #{size})"])

    #   item_payload = data[(i + 4)..]
    #   u = Unpacker.new(item_payload)
    #   (0...(size / 4)).each do |d|
    #     # val = u.get_int
    #     val='EMPTY'
    #     field_name = ''
    #     field_name += meta[:fields][d][:name] unless meta[:fields].nil? || meta[:fields][d].nil?
    #     notes.push([:yellow, i + 4 + (d * 4), 4, "data[#{d}]=#{val} #{field_name}"])
    #   end
    #   skip += 3 + size + 1
    #   # puts "skip=#{skip}"

    #   # next
    #   # next unless item.length == 4

    #   # # reverse for little endian
    #   # id = item[2...4].reverse.map { |b| b.to_s(2).rjust(8, '0') }.join.to_i(2)
    #   # notes.push([:yellow, (index * 4) + 2, 2, "id=#{id}"])
    # end

    hexdump_lines(data.pack('C*'), 1, notes, legend: :inline).each do |hex|
      puts "  #{hex}"
    end

    # ack every snapshot no matter how broken
    @ack_game_tick = game_tick
    return unless (@pred_game_tick - @ack_game_tick).abs > 10

    @pred_game_tick = @ack_game_tick + 1
    # exit
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
