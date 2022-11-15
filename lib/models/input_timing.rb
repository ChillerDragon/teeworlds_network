# frozen_string_literal: true

require_relative '../packer'

##
# InputTiming
#
# Server -> Client
class InputTiming
  attr_accessor :time_left, :intended_tick

  def initialize(hash_or_raw)
    if hash_or_raw.instance_of?(Hash)
      init_hash(hash_or_raw)
    else
      init_raw(hash_or_raw)
    end
  end

  def init_raw(data)
    u = Unpacker.new(data)
    @time_left = u.get_int
    @intended_tick = u.get_int
  end

  def init_hash(attr)
    @time_left = attr[:time_left] || 0
    @intended_tick = attr[:intended_tick] || 0
  end

  def to_h
    {
      time_left: @time_left,
      intended_tick: @intended_tick
    }
  end

  # basically to_network
  # int array the Server sends to the Client
  def to_a
    Packer.pack_int(@time_left) +
      Packer.pack_int(@intended_tick)
  end

  def to_s
    to_h
  end
end
