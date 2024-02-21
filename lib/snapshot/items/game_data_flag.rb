# frozen_string_literal: true

require_relative '../snap_item_base'

class NetObj
  class GameDataFlag < SnapItemBase
    attr_accessor :flag_carrier_red, :flag_carrier_blue,
                  :flag_drop_tick_red, :flag_drop_tick_blue

    def initialize(hash_or_raw)
      @type = NETOBJTYPE_GAMEDATAFLAG
      @field_names = %i[
        flag_carrier_red
        flag_carrier_blue
        flag_drop_tick_red
        flag_drop_tick_blue
      ]
      super
    end

    def self.match_type?(type)
      type == NETOBJTYPE_GAMEDATAFLAG
    end
  end
end
