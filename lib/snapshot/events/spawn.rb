# frozen_string_literal: true

require_relative '../snap_item_base'

class NetEvent
  class Spawn < SnapEventBase
    def initialize(hash_or_raw)
      @type = NETEVENTTYPE_SPAWN
      @field_names = []
      super
    end

    def self.match_type?(type)
      type == NETEVENTTYPE_SPAWN
    end
  end
end
