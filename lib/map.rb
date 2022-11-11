# frozen_string_literal: true

require_relative 'bytes'

class Map
  attr_reader :name, :crc, :size, :sha256, :sha256_str, :sha256_arr

  def initialize(attr = {})
    # map name as String
    @name = attr[:name]

    # crc has to be a positive Integer
    @crc = attr[:crc]

    # size has to be a positive Integer
    @size = attr[:size]

    # sha256 can be:
    #   hex encoded string (64 characters / 32 bytes)
    #   '491af17a510214506270904f147a4c30ae0a85b91bb854395bef8c397fc078c3'
    #
    #   raw string (32 characters)
    #   array of integers representing the bytes (32 elements)
    @sha256 = attr[:sha256]

    if @sha256.instance_of?(String)
      if @sha256.match(/[a-fA-F0-9]{64}/) # str encoded hex
        @sha256_str = @sha256
        @sha256_arr = str_bytes(@sha256)
        @sha256 = @sha256_arr.pack('C*')
      elsif @sha256.length == 32 # raw byte string
        @sha256_arr = @sha256
        @sha256 = @sha256_arr.pack('C*')
        @sha256_str = str_hex(@sha256).gsub(' ', '')
      else
        raise "Error: map raw string expects size 32 but got #{@sha256.size}"
      end
    elsif @sha256.instance_of?(Array) # int byte array
      raise "Error: map sha256 array expects size 32 but got #{@sha256.size}" if @sha256.size != 32

      @sha256_arr = @sha256
      @sha256 = @sha256.pack('C*')
      @sha256_str = @sha256.map { |b| b.to_s(16) }.join
    end
  end
end
