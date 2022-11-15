# frozen_string_literal: true

require_relative '../packer'

##
# InputTiming
#
# Server -> Client
class InputTiming
  attr_accessor :intended_tick, :time_left

  def initialize(hash_or_raw)
    if hash_or_raw.instance_of?(Hash)
      init_hash(hash_or_raw)
    else
      init_raw(hash_or_raw)
    end
  end

  def init_raw(data)
    u = Unpacker.new(data)
    @intended_tick = u.get_int
    @time_left = u.get_int
  end

  def init_hash(attr)
    @intended_tick = attr[:intended_tick] || 0
    @time_left = attr[:time_left] || 0
  end

  def to_h
    {
      intended_tick: @intended_tick,
      time_left: @time_left
    }
  end

  # basically to_network
  # int array the Server sends to the Client
  def to_a
    Packer.pack_int(@intended_tick) +
      Packer.pack_int(@time_left)
  end

  def to_s
    to_h
  end
end
