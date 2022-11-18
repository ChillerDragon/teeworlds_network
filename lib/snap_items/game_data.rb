# frozen_string_literal: true

require_relative '../packer'

class NetObj
  class GameData
    attr_accessor :game_start_tick, :game_state_flags, :game_state_end_tick

    def initialize(hash_or_raw)
      @field_names = %i[
        game_start_tick
        game_state_flags
        game_state_end_tick
      ]
      @fields = @field_names.map do |_|
        0
      end
      @size = @fields.count
      @name = self.class.name
      if hash_or_raw.instance_of?(Hash)
        init_hash(hash_or_raw)
      elsif hash_or_raw.instance_of?(Unpacker)
        init_unpacker(hash_or_raw)
      else
        init_raw(hash_or_raw)
      end
    end

    def self.match_type?(type)
      type == NETOBJTYPE_GAMEDATA
    end

    def validate
      @fields.select(&:nil?).empty?
    end

    def init_unpacker(u)
      @fields.map! do |_|
        # TODO: as of right now it can get nil values here
        #       the fix would be "u.get_int || 0"
        #       but fixing it would probably make it harder
        #       to debug invalid data
        #
        #       but do rethink this in a later point please :)
        #       for now call .validate() everywhere
        u.get_int
      end
    end

    def init_raw(data)
      u = Unpacker.new(data)
      init_unpacker(u)
    end

    def init_hash(attr)
      @fields_names.each do |name|
        instance_variable_set("@#{name}", attr[name] || 0)
      end
    end

    def to_h
      hash = {}
      @field_names.each_with_index do |name, index|
        hash[name] = @fields[index]
      end
      hash
    end

    # basically to_network
    # int array the server sends to the client
    def to_a
      arr = []
      @fields.each do |value|
        arr += Packer.pack_int(value)
      end
      arr
    end

    def to_s
      to_h
    end
  end
end
