# frozen_string_literal: true

require_relative '../snap_item_base'

class NetObj
  class GameDataTeam < SnapItemBase
    attr_accessor :teamscore_red, :teamscore_blue

    def initialize(hash_or_raw)
      @type = NETOBJTYPE_GAMEDATATEAM
      @field_names = %i[
        teamscore_red
        teamscore_blue
      ]
      super
    end

    def self.match_type?(type)
      type == NETOBJTYPE_GAMEDATATEAM
    end
  end
end
