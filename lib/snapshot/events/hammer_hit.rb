# frozen_string_literal: true

require_relative '../snap_item_base'

class NetEvent
  class HammerHit < SnapEventBase
    def initialize(hash_or_raw)
      @type = NETEVENTTYPE_HAMMERHIT
      @field_names = []
      super
    end

    def self.match_type?(type)
      type == NETEVENTTYPE_HAMMERHIT
    end
  end
end
