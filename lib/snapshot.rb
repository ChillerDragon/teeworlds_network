# frozen_string_literal: true

require_relative 'snap_items/game_data'
require_relative 'snap_items/character'
require_relative 'packer'

class SnapshotUnpacker
  def snap_single(chunk)
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
    notes = []

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

    item_type = u.get_int
    id_parsed = u.parsed.last
    while item_type
      obj = nil
      if NetObj::GameData.match_type?(item_type)
        obj = NetObj::GameData.new(u)
        notes += obj.notes
        # p obj
      elsif NetObj::Character.match_type?(item_type)
        obj = NetObj::Character.new(u)
        notes += obj.notes
        # p obj
      elsif @verbose
        puts "no match #{item_type}"
      end
      if obj
        notes.push([
                     :green,
                     id_parsed[:pos],
                     id_parsed[:len],
                     "type=#{item_type} #{obj.name}"
                   ])
      else
        notes.push([
                     :bg_red,
                     id_parsed[:pos],
                     id_parsed[:len],
                     "invalid_type=#{item_type}"
                   ])
      end
      item_type = u.get_int
      id_parsed = u.parsed.last
    end

    # item_delta = u.get_int
    # while item_delta
    #   item_type = item_delta
    #   item_meta = @snap_items[item_type]
    #   item_name = item_meta[:name]

    #   p = u.parsed.last
    #   notes.push([:green, p[:pos], p[:len], "type = #{item_type} #{item_name}"])

    #   item_id = u.get_int
    #   p = u.parsed.last
    #   notes.push([:cyan, p[:pos], p[:len], "id=#{item_id}"])

    #   size = item_meta[:size]
    #   (0...size).each do |i|
    #     val = u.get_int
    #     p = u.parsed.last
    #     color = (i % 2).zero? ? :yellow : :pink
    #     fields = item_meta[:fields]
    #     desc = ''
    #     desc = fields[i][:name] unless fields.nil? || fields[i].nil?
    #     notes.push([color, p[:pos], p[:len], "data[#{i}]=#{val} #{desc}"])
    #   end
    #   item_delta = u.get_int
    # end
    hexdump_lines(data.pack('C*'), 1, notes, legend: :inline).each do |hex|
      puts "  #{hex}"
    end

    game_tick
  end
end
