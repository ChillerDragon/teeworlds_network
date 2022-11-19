# frozen_string_literal: true

require_relative '../snap_item_base'

class NetObj
  class GameData < SnapItemBase
    attr_accessor :game_start_tick, :game_state_flags, :game_state_end_tick

    def initialize(hash_or_raw)
      @field_names = %i[
        game_start_tick
        game_state_flags
        game_state_end_tick
      ]
      super
    end

    def self.match_type?(type)
      type == NETOBJTYPE_GAMEDATA
    end
  end
end
