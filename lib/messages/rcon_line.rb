# frozen_string_literal: true

require_relative '../packer'

##
# RconLine
#
# Server -> Client
class RconLine
  attr_accessor :command

  def initialize(hash_or_raw)
    if hash_or_raw.instance_of?(Hash)
      init_hash(hash_or_raw)
    else
      init_raw(hash_or_raw)
    end
  end

  def init_raw(data)
    u = Unpacker.new(data)
    @command = u.get_string
  end

  def init_hash(attr)
    @command = attr[:command] || 'hello world'
  end

  def to_h
    {
      command: @command
    }
  end

  # basically to_network
  # int array the Server sends to the Client
  def to_a
    Packer.pack_str(@command)
  end

  def to_s
    to_h
  end
end
