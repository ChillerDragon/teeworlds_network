# frozen_string_literal: true

require_relative '../snap_item_base'

class NetObj
  class Projectile < SnapItemBase
    attr_accessor :x, :y, :vel_x, :vel_y, :type, :start_tick

    def initialize(hash_or_raw)
      @field_names = %i[
        x
        y
        vel_x
        vel_y
        type
        start_tick
      ]
      super
    end

    def self.match_type?(type)
      type == NETOBJTYPE_PROJECTILE
    end
  end
end
