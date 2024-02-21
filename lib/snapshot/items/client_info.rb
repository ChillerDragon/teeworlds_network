# frozen_string_literal: true

require_relative '../snap_item_base'

class NetObj
  class ClientInfo < SnapItemBase
    attr_accessor :local, :team

    def initialize(hash_or_raw)
      @type = NETOBJTYPE_DE_CLIENTINFO
      @field_names = %i[
        local
        team
      ]
      super
      raise 'ClientInfo includes strings that is not supported yet'
    end

    def self.match_type?(type)
      type == NETOBJTYPE_DE_CLIENTINFO
    end
  end
end
