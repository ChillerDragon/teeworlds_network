# frozen_string_literal: true

require_relative '../../packer'
require_relative '../snap_item_base'

class NetObj
  class Character < SnapItemBase
    attr_accessor :tick, :x, :y, :vel_x, :vel_y, :angle, :direction, :jumped, :hooked_player, :hook_state, :hook_tick,
                  :hook_x, :hook_y, :hook_dx, :hook_dy,
                  :health, :armor, :ammo_count, :weapon, :emote, :attack_tick, :triggered_events

    def initialize(hash_or_raw)
      @field_names = %i[
        tick
        x
        y
        vel_x
        vel_y
        angle
        direction
        jumped
        hooked_player
        hook_state
        hook_tick
        hook_x
        hook_y
        hook_dx
        hook_dy
        health
        armor
        ammo_count
        weapon
        emote
        attack_tick
        triggered_events
      ]
      super
    end

    def self.match_type?(type)
      type == NETOBJTYPE_CHARACTER
    end
  end
end
