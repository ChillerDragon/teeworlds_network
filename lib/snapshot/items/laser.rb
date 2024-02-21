# frozen_string_literal: true

require_relative '../snap_item_base'

class NetObj
  class Laser < SnapItemBase
    attr_accessor :x, :y, :from_x, :from_y, :start_tick

    def initialize(hash_or_raw)
      @type = NETOBJTYPE_LASER
      @field_names = %i[
        x
        y
        from_x
        from_y
        start_tick
      ]
      super
    end

    def self.match_type?(type)
      type == NETOBJTYPE_LASER
    end
  end
end
