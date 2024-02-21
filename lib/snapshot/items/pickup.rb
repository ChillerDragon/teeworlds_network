# frozen_string_literal: true

require_relative '../snap_item_base'

class NetObj
  class Pickup < SnapItemBase
    attr_accessor :x, :y, :type

    def initialize(hash_or_raw)
      @type = NETOBJTYPE_PICKUP
      @field_names = %i[
        x
        y
        type
      ]
      super
    end

    def self.match_type?(type)
      type == NETOBJTYPE_PICKUP
    end
  end
end
