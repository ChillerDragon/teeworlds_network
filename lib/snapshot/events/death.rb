# frozen_string_literal: true

require_relative '../snap_event_base'

class NetEvent
  class Death < SnapEventBase
    attr_accessor :client_id

    def initialize(hash_or_raw)
      @type = NETEVENTTYPE_DEATH
      @field_names = %i[
        client_id
      ]
      super
    end

    def self.match_type?(type)
      type == NETEVENTTYPE_DEATH
    end
  end
end
