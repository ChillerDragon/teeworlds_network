# frozen_string_literal: true

require_relative '../snap_item_base'

class NetEvent
  class Explosion < SnapEventBase
    def initialize(hash_or_raw)
      @field_names = []
      super
    end

    def self.match_type?(type)
      type == NETEVENTTYPE_EXPLOSION
    end
  end
end
