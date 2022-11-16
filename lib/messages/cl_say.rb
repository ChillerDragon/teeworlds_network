# frozen_string_literal: true

require_relative '../packer'

##
# ClSay
#
# Client -> Server
class ClSay
  attr_accessor :mode, :target_id, :message

  def initialize(hash_or_raw)
    if hash_or_raw.instance_of?(Hash)
      init_hash(hash_or_raw)
    else
      init_raw(hash_or_raw)
    end
  end

  def init_raw(data)
    u = Unpacker.new(data)
    @mode = u.get_int
    @target_id = u.get_int
    @message = u.get_string
  end

  def init_hash(attr)
    @mode = attr[:mode] || 0
    @target_id = attr[:target_id] || 0
    @message = attr[:message] || 0
  end

  def to_h
    {
      mode: @mode,
      target_id: @target_id,
      message: @message
    }
  end

  # basically to_network
  # int array the client sends to the server
  def to_a
    Packer.pack_int(@mode) +
      Packer.pack_int(@target_id) +
      Packer.pack_str(@message)
  end

  def to_s
    to_h
  end
end
