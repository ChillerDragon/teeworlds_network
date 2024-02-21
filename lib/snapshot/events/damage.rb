# frozen_string_literal: true

require_relative '../snap_event_base'

class NetEvent
  class Damage < SnapEventBase
    attr_accessor :client_id, :angle, :health_ammount, :armor_amount, :self

    def initialize(hash_or_raw)
      @type = NETEVENTTYPE_DAMAGE
      @field_names = %i[
        client_id
        angle
        health_ammount
        armor_amount
        self
      ]
      super
    end

    def self.match_type?(type)
      type == NETEVENTTYPE_DAMAGE
    end
  end
end
