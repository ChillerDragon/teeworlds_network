# frozen_string_literal: true

require_relative '../packer'

##
# MaplistEntryAdd
#
# Server -> Client
class MaplistEntryAdd
  attr_accessor :name

  def initialize(hash_or_raw)
    if hash_or_raw.instance_of?(Hash)
      init_hash(hash_or_raw)
    else
      init_raw(hash_or_raw)
    end
  end

  def init_raw(data)
    u = Unpacker.new(data)
    @name = u.get_string(SANITIZE_CC)
  end

  def init_hash(attr)
    @name = attr[:name] || 'TODO: fill default'
  end

  def to_h
    {
      name: @name
    }
  end

  # basically to_network
  # int array the Server sends to the Client
  def to_a
    Packer.pack_str(@name)
  end

  def to_s
    to_h
  end
end
