# frozen_string_literal: true

require_relative '../snap_event_base'

class NetEvent
  class SoundWorld < SnapEventBase
    attr_accessor :sound_id

    def initialize(hash_or_raw)
      @type = NETEVENTTYPE_SOUNDWORLD
      @field_names = %i[
        sound_id
      ]
      super
    end

    def self.match_type?(type)
      type == NETEVENTTYPE_SOUNDWORLD
    end
  end
end
