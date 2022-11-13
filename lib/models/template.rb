# frozen_string_literal: true

require_relative '../packer'

##
# SamplePacket
#
# Client -> Server
class SamplePacket
  attr_accessor :foo, :bar

  def initialize(hash_or_raw)
    if hash_or_raw.instance_of?(Hash)
      init_hash(hash_or_raw)
    else
      init_raw(hash_or_raw)
    end
  end

  def init_raw(data)
    u = Unpacker.new(data)
    @foo = u.get_int
    @bar = u.get_string
  end

  def init_hash(attr)
    @foo = attr[:foo] || 0
    @bar = attr[:bar] || 'sample'
  end

  def to_h
    {
      foo: @foo,
      bar: @bar
    }
  end

  # basically to_network
  # int array the client sends to the server
  def to_a
    Packer.pack_int(@foo) +
      Packer.pack_str(@bar)
  end

  def to_s
    to_h
  end
end
