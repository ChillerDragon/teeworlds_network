# frozen_string_literal: true

require_relative '../packer'

##
# SvClientDrop
#
# Server -> Client
class SvClientDrop
  attr_accessor :client_id, :reason, :silent

  def initialize(hash_or_raw)
    if hash_or_raw.instance_of?(Hash)
      init_hash(hash_or_raw)
    else
      init_raw(hash_or_raw)
    end
  end

  def init_raw(data)
    u = Unpacker.new(data)
    @client_id = u.get_int
    @reason = u.get_string
    @silent = u.get_int
  end

  def init_hash(attr)
    @client_id = attr[:client_id] || 0
    @reason = attr[:reason] || ''
    @silent = attr[:silent] || false
  end

  def to_h
    {
      client_id: @client_id,
      reason: @reason,
      silent: @silent
    }
  end

  def silent?
    !@silent.zero?
  end

  # basically to_network
  # int array the Server sends to the Client
  def to_a
    Packer.pack_int(@client_id) +
      Packer.pack_str(@reason) +
      Packer.pack_int(@silent)
  end

  def to_s
    to_h
  end
end
