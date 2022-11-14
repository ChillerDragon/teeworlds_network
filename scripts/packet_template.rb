# frozen_string_literal: true

require_relative '../packer'

##
# PacketName
#
# SENDER -> RECEIVER
class PacketName
  attr_accessor :foo, :bar

  def initialize(hash_or_raw)
    if hash_or_raw.instance_of?(Hash)
      init_hash(hash_or_raw)
    else
      init_raw(hash_or_raw)
    end
  end

  def init_raw(data)
    Unpacker.new(data)
  end

  def init_hash(attr)
    @foo = attr[:foo] || 0
  end

  def to_h
    { foo: @foo, bar: @bar }
  end

  # basically to_network
  # int array the SENDER sends to the RECEIVER
  def to_a
    Packer.pack_int(@foo) +
      Packer.pack_str(@bar)
  end

  def to_s
    to_h
  end
end
