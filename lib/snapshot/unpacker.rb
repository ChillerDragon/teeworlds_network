# frozen_string_literal: true

require_relative 'items/game_data'
require_relative 'items/character'
require_relative 'items/player_info'
require_relative 'items/projectile'
require_relative '../packer'

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

    invalid = false
    item_type = u.get_int
    id_parsed = u.parsed.last
    while item_type
      obj = nil
      if NetObj::GameData.match_type?(item_type)
        obj = NetObj::GameData.new(u)
      elsif NetObj::Character.match_type?(item_type)
        obj = NetObj::Character.new(u)
      elsif NetObj::PlayerInfo.match_type?(item_type)
        obj = NetObj::PlayerInfo.new(u)
      elsif NetObj::Projectile.match_type?(item_type)
        obj = NetObj::Projectile.new(u)
      elsif @verbose
        puts "no match #{item_type}"
      end
      if obj
        notes += obj.notes
        notes.push([
                     :green,
                     id_parsed[:pos],
                     id_parsed[:len],
                     "type=#{item_type} #{obj.name}"
                   ])
      else
        invalid = true
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

    hexdump_lines(data.pack('C*'), 1, notes, legend: :inline).each do |hex|
      puts "  #{hex}"
    end

    # exit 1 if invalid

    game_tick
  end
end
