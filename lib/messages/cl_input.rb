# frozen_string_literal: true

require_relative '../packer'

##
# ClInput
#
# Client -> Server
class ClInput
  attr_accessor :ack_game_tick, :prediction_tick, :size, :direction, :target_x, :target_y, :jump, :fire, :hook, :player_flags, :wanted_weapon, :next_weapon, :prev_weapon, :ping

  def initialize(hash_or_raw)
    if hash_or_raw.instance_of?(Hash)
      init_hash(hash_or_raw)
    else
      init_raw(hash_or_raw)
    end
  end

  def init_raw(data)
    u = Unpacker.new(data)
    @ack_game_tick = u.get_int
    @prediction_tick = u.get_int
    @size = u.get_int
    @direction = u.get_int
    @target_x = u.get_int
    @target_y = u.get_int
    @jump = u.get_int
    @fire = u.get_int
    @hook = u.get_int
    @player_flags = u.get_int
    @wanted_weapon = u.get_int
    @next_weapon = u.get_int
    @prev_weapon = u.get_int
    @ping = u.get_int
  end

  def init_hash(attr)
    @ack_game_tick = attr[:ack_game_tick] || 0
    @prediction_tick = attr[:prediction_tick] || 0
    @size = attr[:size] || 0
    @direction = attr[:direction] || 0
    @target_x = attr[:target_x] || 0
    @target_y = attr[:target_y] || 0
    @jump = attr[:jump] || 0
    @fire = attr[:fire] || 0
    @hook = attr[:hook] || 0
    @player_flags = attr[:player_flags] || 0
    @wanted_weapon = attr[:wanted_weapon] || 0
    @next_weapon = attr[:next_weapon] || 0
    @prev_weapon = attr[:prev_weapon] || 0
    @ping = attr[:ping] || 0
  end

  def to_h
    {
      ack_game_tick: @ack_game_tick,
      prediction_tick: @prediction_tick,
      size: @size,
      direction: @direction,
      target_x: @target_x,
      target_y: @target_y,
      jump: @jump,
      fire: @fire,
      hook: @hook,
      player_flags: @player_flags,
      wanted_weapon: @wanted_weapon,
      next_weapon: @next_weapon,
      prev_weapon: @prev_weapon,
      ping: @ping
    }
  end

  # basically to_network
  # int array the Client sends to the Server
  def to_a
    Packer.pack_int(@ack_game_tick) +
      Packer.pack_int(@prediction_tick) +
      Packer.pack_int(@size) +
      Packer.pack_int(@direction) +
      Packer.pack_int(@target_x) +
      Packer.pack_int(@target_y) +
      Packer.pack_int(@jump) +
      Packer.pack_int(@fire) +
      Packer.pack_int(@hook) +
      Packer.pack_int(@player_flags) +
      Packer.pack_int(@wanted_weapon) +
      Packer.pack_int(@next_weapon) +
      Packer.pack_int(@prev_weapon) +
      Packer.pack_int(@ping)
  end

  def to_s
    to_h
  end
end
