# frozen_string_literal: true

require_relative '../packer'

##
# RconCmdAdd
#
# Server -> Client
class RconCmdAdd
  attr_accessor :name, :help, :params

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
    @help = u.get_string(SANITIZE_CC)
    @params = u.get_string(SANITIZE_CC)
  end

  def init_hash(attr)
    @name = attr[:name] || ''
    @help = attr[:help] || ''
    @params = attr[:params] || ''
  end

  def to_h
    {
      name: @name,
      help: @help,
      params: @params
    }
  end

  # basically to_network
  # int array the Server sends to the Client
  def to_a
    Packer.pack_str(@name) +
      Packer.pack_str(@help) +
      Packer.pack_str(@params)
  end

  def to_s
    to_h
  end
end
