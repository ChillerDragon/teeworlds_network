# frozen_string_literal: true

require_relative '../snap_item_base'

class NetObj
  class Flag < SnapItemBase
    attr_accessor :x, :y, :team

    def initialize(hash_or_raw)
      @field_names = %i[
        x
        y
        team
      ]
      super
    end

    def self.match_type?(type)
      type == NETOBJTYPE_FLAG
    end
  end
end
