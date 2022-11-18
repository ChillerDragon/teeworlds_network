# frozen_string_literal: true

require_relative '../packer'

class NetObj
  class GameData
    attr_accessor :game_start_tick, :game_state_flags, :game_state_end_tick

    def initialize(hash_or_raw)
      if hash_or_raw.instance_of?(Hash)
        init_hash(hash_or_raw)
      else
        init_raw(hash_or_raw)
      end
      @fields = instance_variables.map { |f| f.to_s[1..] }
      @size = @fields.count
    end

    def match_type?(type)
      type == NETOBJTYPE_GAMEDATA
    end

    def init_raw(data)
      u = Unpacker.new(data)
      @game_start_tick = u.get_int
      @game_state_flags = u.get_int
      @game_state_end_tick = u.get_int
    end

    def init_hash(attr)
      @game_start_tick = attr[:game_start_tick] || 0
      @game_state_flags = attr[:game_state_flags] || 0
      @game_state_end_tick = attr[:game_state_end_tick] || 0
    end

    def to_h
      {
        game_start_tick: @game_start_tick,
        game_state_flags: @game_state_flags,
        game_state_end_tick: @game_state_end_tick
      }
    end

    # basically to_network
    # int array the server sends to the client
    def to_a
      Packer.pack_int(@game_start_tick) +
        Packer.pack_int(@game_state_flags) +
        Packer.pack_int(@game_state_end_tick)
    end

    def to_s
      to_h
    end
  end
end

p NetObj::GameData.new([])
