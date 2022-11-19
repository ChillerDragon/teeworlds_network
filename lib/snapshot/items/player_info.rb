# frozen_string_literal: true

require_relative '../snap_item_base'

class NetObj
  class PlayerInfo < SnapItemBase
    attr_accessor :player_flags, :score, :latency

    def initialize(hash_or_raw)
      @field_names = %i[
        player_flags
        score
        latency
      ]
      super
    end

    def self.match_type?(type)
      type == NETOBJTYPE_PLAYERINFO
    end
  end
end
