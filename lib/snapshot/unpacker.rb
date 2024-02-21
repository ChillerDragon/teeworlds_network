# frozen_string_literal: true

require_relative 'items/game_data'
require_relative 'items/character'
require_relative 'items/projectile'
require_relative 'items/pickup'
require_relative 'items/flag'
require_relative 'items/game_data_team'
require_relative 'items/game_data_flag'
require_relative 'items/player_input'
require_relative 'items/laser'
require_relative 'items/player_info'
require_relative 'items/spectator_info'
require_relative 'items/client_info'
require_relative 'events/sound_world'
require_relative 'events/explosion'
require_relative 'events/spawn'
require_relative 'events/damage'
require_relative 'events/death'
require_relative 'events/hammer_hit'
require_relative '../packer'
require_relative 'snapshot'

class DDNetSnapItem
  attr_accessor :notes, :name

  @@registered_types = []

  # TODO: rename to register uuid?!
  def initialize(u, id)
    @name = 'ddnet_uuid'
    @notes = []
    len = u.get_int
    p = u.parsed.last
    @notes.push([:green, p[:pos], p[:len], "len=#{len}"])
    (0...len).each do |i|
      val = u.get_int
      p = u.parsed.last
      col = (i % 2).zero? ? :bg_pink : :bg_yellow
      @notes.push([col, p[:pos], p[:len], "val=#{val}"])
    end
    @@registered_types.push(id)
  end

  # parses registered ddnet items
  def self.parse(u, _item_type)
    id = u.get_int
    p = u.parsed.last
    notes = []
    notes.push([:cyan, p[:pos], p[:len], "id=#{id}"])
    len = u.get_int
    p = u.parsed.last
    notes.push([:green, p[:pos], p[:len], "len=#{len}"])
    (0...len).each do |i|
      val = u.get_int
      p = u.parsed.last
      col = (i % 2).zero? ? :bg_pink : :bg_yellow
      notes.push([col, p[:pos], p[:len], "val=#{val}"])
    end
    notes
  end

  def self.valid_type?(type)
    @@registered_types.include?(type)
  end
end

class SnapshotUnpacker
  def initialize(client)
    @client = client
    # @type verbose [Boolean]
    @verbose = client.verbose_snap
  end

  def unpack_ddnet_item(u, notes)
    id = u.get_int
    p = u.parsed.last
    notes.push([:cyan, p[:pos], p[:len], "id=#{id}"])
    return nil if id < 0x4000 # ddnet offset uuid type

    DDNetSnapItem.new(u, id)
  end

  ##
  # Given a NetChunk this method
  # dissects the snapshot header
  # and its payload (snap items)
  #
  # @return [Snapshot]
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

    if @verbose
      puts ">>> snap #{snap_name} (#{msg_id})"
      puts "  id=#{msg_id} game_tick=#{game_tick} delta_tick=#{delta_tick}"
      puts "  num_parts=#{num_parts} part=#{part} crc=#{crc} part_size=#{part_size}"
      puts "\n  header:"
    end

    header = []
    notes = []
    u.parsed.each_with_index do |parsed, index|
      color = (index % 2).zero? ? :green : :pink
      txt = "#{parsed[:type]} #{parsed[:value]}"
      txt += " >> 1 = #{parsed[:value] >> 1}" if header.empty?
      notes.push([color, parsed[:pos], parsed[:len], txt])
      header += parsed[:raw]
    end

    if @verbose
      hexdump_lines(header.pack('C*'), 1, notes, legend: :inline).each do |hex|
        puts "  #{hex}"
      end
      puts "\n  payload:"
    end

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
    # @type snap_items [Array<SnapItemBase>]
    snap_items = []
    while item_type
      obj = nil
      if NetObj::PlayerInput.match_type?(item_type)
        obj = NetObj::PlayerInput.new(u)
      elsif NetObj::Projectile.match_type?(item_type)
        obj = NetObj::Projectile.new(u)
      elsif NetObj::Laser.match_type?(item_type)
        obj = NetObj::Laser.new(u)
      elsif NetObj::Pickup.match_type?(item_type)
        obj = NetObj::Pickup.new(u)
      elsif NetObj::Flag.match_type?(item_type)
        obj = NetObj::Flag.new(u)
      elsif NetObj::GameData.match_type?(item_type)
        obj = NetObj::GameData.new(u)
      elsif NetObj::GameDataTeam.match_type?(item_type)
        obj = NetObj::GameDataTeam.new(u)
      elsif NetObj::GameDataFlag.match_type?(item_type)
        obj = NetObj::GameDataFlag.new(u)
      elsif NetObj::Character.match_type?(item_type)
        obj = NetObj::Character.new(u)
      elsif NetObj::PlayerInfo.match_type?(item_type)
        obj = NetObj::PlayerInfo.new(u)
      elsif NetObj::SpectatorInfo.match_type?(item_type)
        obj = NetObj::SpectatorInfo.new(u)
      elsif NetObj::ClientInfo.match_type?(item_type)
        obj = NetObj::ClientInfo.new(u)
      elsif NetEvent::Explosion.match_type?(item_type)
        obj = NetEvent::Explosion.new(u)
      elsif NetEvent::SoundWorld.match_type?(item_type)
        obj = NetEvent::SoundWorld.new(u)
      elsif NetEvent::Spawn.match_type?(item_type)
        obj = NetEvent::Spawn.new(u)
      elsif NetEvent::Damage.match_type?(item_type)
        obj = NetEvent::Damage.new(u)
      elsif NetEvent::Death.match_type?(item_type)
        obj = NetEvent::Death.new(u)
      elsif NetEvent::HammerHit.match_type?(item_type)
        obj = NetEvent::HammerHit.new(u)
      elsif @verbose
        puts "no match #{item_type}"
      end
      obj = unpack_ddnet_item(u, notes) if !obj && item_type.zero?
      if obj
        snap_items.push(obj)
        notes += obj.notes
        notes.push([
                     :green,
                     id_parsed[:pos],
                     id_parsed[:len],
                     "type=#{item_type} #{obj.name}"
                   ])
      elsif DDNetSnapItem.valid_type?(item_type)
        notes.push([
                     :green,
                     id_parsed[:pos],
                     id_parsed[:len],
                     "type=#{item_type} ddnet_ex_reg"
                   ])
        notes += DDNetSnapItem.parse(u, item_type)
      elsif item_type < 50 # TODO: i made up this magic number xd
        #                          figure out what a sane
        #                          limit for the type is
        #                          something that is a bit
        #                          future proof
        #                          and also strict enough
        #                          to alert when something
        #                          goes wrong
        # item with non pre-agreed size
        # first int of the payload is the size of the payload
        id = u.get_int
        p = u.parsed.last
        notes.push([:cyan, p[:pos], p[:len], "id=#{id}"])
        len = u.get_int
        p = u.parsed.last
        notes.push([:green, p[:pos], p[:len], "len=#{len}"])
        (0...len).each do |i|
          val = u.get_int
          p = u.parsed.last
          col = (i % 2).zero? ? :bg_pink : :bg_yellow
          notes.push([col, p[:pos], p[:len], "val=#{val}"])
        end
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

    if @verbose
      hexdump_lines(data.pack('C*'), 1, notes, legend: :inline).each do |hex|
        puts "  #{hex}"
      end
    end

    if invalid
      # make sure if we did not print the hex already
      # to print it now as error message
      unless @verbose
        hexdump_lines(data.pack('C*'), 1, notes, legend: :inline).each do |hex|
          puts "  #{hex}"
        end
      end
      puts 'Error: got invalid snap item'
      @client.disconnect
      exit 1
    end

    snapshot = Snapshot.new(snap_items)
    snapshot.game_tick = game_tick
    snapshot
  end
end
