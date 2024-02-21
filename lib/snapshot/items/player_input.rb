# frozen_string_literal: true

require_relative '../snap_item_base'

class NetObj
  class PlayerInput < SnapItemBase
    attr_accessor :direction, :target_x, :target_y,
                  :jump, :fire, :hook,
                  :player_flags, :wanted_weapon,
                  :next_weapon, :prev_weapon

    def initialize(hash_or_raw)
      @type = NETOBJTYPE_PLAYERINPUT
      @field_names = %i[
        direction
        target_x
        target_y
        jump
        fire
        hook
        player_flags
        wanted_weapon
        next_weapon
        prev_weapon
      ]
      super
    end

    def self.match_type?(type)
      type == NETOBJTYPE_PLAYERINPUT
    end
  end
end
