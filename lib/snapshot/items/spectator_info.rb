# frozen_string_literal: true

require_relative '../snap_item_base'

class NetObj
  class SpectatorInfo < SnapItemBase
    attr_accessor :spec_mode, :spectator_id, :x, :y

    def initialize(hash_or_raw)
      @field_names = %i[
        spec_mode
        spectator_id
        x
        y
      ]
      super
    end

    def self.match_type?(type)
      type == NETOBJTYPE_SPECTATORINFO
    end
  end
end
