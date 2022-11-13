# frozen_string_literal: true

require_relative 'models/net_addr'
require_relative 'models/packet_flags'

require 'huffman_tw'

# Class holding the parsed packet data
class Packet
  attr_reader :flags, :payload, :addr
  attr_accessor :client_id, :client

  def initialize(data, prefix = '')
    # @data and @payload
    # are strings representing the raw bytes
    #
    # @prefix is a String that will be displayed
    #         when printing the packet
    #         use '>' and '<' for example to indicate
    #         network direction (client/server)
    @prefix = prefix
    @addr = NetAddr.new(nil, nil)
    @huffman = Huffman.new
    @client_id = nil
    @client = nil
    @data = data
    flags_byte = @data[0].unpack('B*')
    @flags = PacketFlags.new(flags_byte.first[2..5]).hash
    @payload = @data[PACKET_HEADER_SIZE..]
    return unless  flags_compressed

    @payload = @huffman.decompress(@payload.unpack('C*'))
    @payload = @payload.pack('C*')
  end

  def annotate_first_row(bytes)
    header = bytes[0..2].join(' ').yellow
    token = bytes[3..6].join(' ').green
    payload = bytes[7..].join(' ')
    puts @prefix + "  data: #{[header, token, payload].join(' ')}"
    print "#{@prefix}        "
    print 'header'.ljust(3 * 3, ' ').yellow
    print 'token'.ljust(4 * 3, ' ').green
    puts 'data'
  end

  def to_s
    puts "#{@prefix}Packet"
    puts @prefix + "  flags: #{@flags}"
    bytes = str_hex(@data).split
    # TODO: check terminal size?
    max_width = 14
    rows = bytes.groups_of(max_width)
    annotate_first_row(rows.first)
    rows[1..].each do |row|
      print "#{@prefix}        "
      puts row.join(' ')
    end
    puts ''
  end

  def flags_compressed
    @flags[:compressed]
  end

  def flags_connless
    @flags[:connection] == false
  end

  def flags_control
    @flags[:control]
  end
end
