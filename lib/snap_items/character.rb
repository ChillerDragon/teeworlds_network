# frozen_string_literal: true

require_relative '../packer'

class NetObj
  class Character
    attr_accessor :tick, :x, :y, :vel_x, :vel_y, :angle, :direction, :jumped, :hooked_player, :hook_state, :hook_tick,
                  :hook_x, :hook_y, :hook_dx, :hook_dy,
                  :health, :armor, :ammo_count, :weapon, :emote, :attack_tick, :triggered_events
    attr_reader :notes, :name, :id

    def initialize(hash_or_raw)
      @field_names = %i[
        tick
        x
        y
        vel_x
        vel_y
        angle
        direction
        jumped
        hooked_player
        hook_state
        hook_tick
        hook_x
        hook_y
        hook_dx
        hook_dy
        health
        armor
        ammo_count
        weapon
        emote
        attack_tick
        triggered_events
      ]
      @fields = @field_names.map do |_|
        0
      end
      @size = @fields.count
      @name = self.class.name
      @notes = [] # hexdump annotation notes
      if hash_or_raw.instance_of?(Hash)
        init_hash(hash_or_raw)
      elsif hash_or_raw.instance_of?(Unpacker)
        init_unpacker(hash_or_raw)
      else
        init_raw(hash_or_raw)
      end
    end

    def self.match_type?(type)
      type == NETOBJTYPE_CHARACTER
    end

    def validate
      @fields.select(&:nil?).empty?
    end

    def init_unpacker(u)
      @id = u.get_int
      p = u.parsed.last
      @notes.push([:cyan, p[:pos], p[:len], "id=#{@id}"])
      i = 0
      @fields.map! do |_|
        # TODO: as of right now it can get nil values here
        #       the fix would be "u.get_int || 0"
        #       but fixing it would probably make it harder
        #       to debug invalid data
        #
        #       but do rethink this in a later point please :)
        #       for now call .validate() everywhere
        val = u.get_int

        p = u.parsed.last
        color = (i % 2).zero? ? :yellow : :pink
        desc = @field_names[i]
        @notes.push([color, p[:pos], p[:len], "data[#{i}]=#{val} #{desc}"])
        i += 1

        val
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
