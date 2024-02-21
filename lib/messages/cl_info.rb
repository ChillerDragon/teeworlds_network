# frozen_string_literal: true

require_relative '../packer'

##
# ClInfo
#
# Client -> Server
class ClInfo
  attr_accessor :net_version, :password, :client_version

  def initialize(hash_or_raw)
    if hash_or_raw.instance_of?(Hash)
      init_hash(hash_or_raw)
    else
      init_raw(hash_or_raw)
    end
  end

  def init_raw(data)
    u = Unpacker.new(data)
    @net_version = u.get_string
    @password = u.get_string
    @client_version = u.get_int
  end

  def init_hash(attr)
    @net_version = attr[:net_version] || 'TODO: fill default'
    @password = attr[:password] || 'TODO: fill default'
    @client_version = attr[:client_version] || 0
  end

  def to_h
    {
      net_version: @net_version,
      password: @password,
      client_version: @client_version
    }
  end

  # basically to_network
  # int array the Client sends to the Server
  def to_a
    Packer.pack_str(@net_version) +
      Packer.pack_str(@password) +
      Packer.pack_int(@client_version)
  end

  def to_s
    to_h
  end
end
