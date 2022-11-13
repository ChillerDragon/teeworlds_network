# frozen_string_literal: true

require_relative '../bytes'

class Map
  attr_reader :name, :crc, :crc_str, :crc_arr, :size, :sha256, :sha256_str, :sha256_arr

  def initialize(attr = {})
    # map name as String
    @name = attr[:name]

    # crc hex encoded string (8 characters / 4 bytes)
    @crc = attr[:crc]
    raise "Error: map crc invalid type: #{@crc.class}" unless @crc.instance_of?(String)

    unless @crc.match(/[a-fA-F0-9]{8}/) # str encoded hex
      raise "Error: map crc raw string expects size 8 but got #{@crc.size}"
    end

    @crc_str = @crc
    @crc_arr = str_bytes(@crc)
    @crc = @crc_arr.pack('C*')

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
        raise "Error: map sha256 raw string expects size 64 but got #{@sha256.size}"
      end
    elsif @sha256.instance_of?(Array) # int byte array
      raise "Error: map sha256 array expects size 32 but got #{@sha256.size}" if @sha256.size != 32

      @sha256_arr = @sha256
      @sha256 = @sha256.pack('C*')
      @sha256_str = @sha256.map { |b| b.to_s(16).rjust(2, '0') }.join
    else
      raise "Error: map sha256 invalid type: #{@sha256.class}"
    end
  end
end
