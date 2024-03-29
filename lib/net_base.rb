# frozen_string_literal: true

require_relative 'models/token'

##
# Turns int into network byte
#
# Takes a NETMSGTYPE_CL_* integer
# and returns a byte that can be send over
# the network
def pack_msg_id(msg_id, options = { system: false })
  (msg_id << 1) | (options[:system] ? 1 : 0)
end

##
# NetBase
#
# Lowest network layer logic. Sends packets via udp.
# Also adding the teeworlds protocol packet header.
class NetBase
  attr_accessor :ack
  attr_reader :peer_token

  def initialize(opts = {})
    @verbose = opts[:verbose] || false
    @ip = nil
    @port = nil
    @s = nil
    @ack = 0
    @peer_token = [0xFF, 0xFF, 0xFF, 0xFF].map { |b| b.to_s(16).rjust(2, '0') }.join
  end

  def bind(socket)
    @s = socket
  end

  def connect(socket, ip, port)
    @s = socket
    @ip = ip
    @port = port
    @ack = 0
  end

  def set_peer_token(token)
    SecurityToken.validate(token)
    @peer_token = token
  end

  ##
  # Sends a packing setting the proper header for you
  #
  # @param payload [Array] The Integer list representing the data after the header
  # @param opts [Hash] :chunks, :client and packet header flags for more details check the class +PacketFlags+
  def send_packet(payload, opts = { chunks: 1, client: nil, addr: nil })
    # unsigned char flags_ack;    // 6bit flags, 2bit ack
    # unsigned char ack;          // 8bit ack
    # unsigned char numchunks;    // 8bit chunks
    # unsigned char token[4];     // 32bit token
    # // ffffffaa
    # // aaaaaaaa
    # // NNNNNNNN
    # // TTTTTTTT
    # // TTTTTTTT
    # // TTTTTTTT
    # // TTTTTTTT
    if @s.nil?
      puts 'Error: no active socket'
      return
    end
    flags_bits = PacketFlags.new(opts).bits
    ack = @ack
    ip = @ip
    port = @port
    token = @peer_token
    unless opts[:client].nil?
      ack = opts[:client].ack
      ip = opts[:client].addr.ip
      port = opts[:client].addr.port
      token = opts[:client].token
    end
    unless opts[:addr].nil?
      ip = opts[:addr].ip
      port = opts[:addr].port
    end
    #          unused flags       ack                             num chunks
    #              ff ffff        aa aaaa aaaa                    NNNN NNNN
    header_bits = "00#{flags_bits}#{ack.to_s(2).rjust(10, '0')}#{opts[:chunks].to_s(2).rjust(8, '0')}"

    header = header_bits.chars.groups_of(8).map do |eight_bits|
      eight_bits.join.to_i(2)
    end

    header += str_bytes(token)
    data = (header + payload).pack('C*')
    client = opts[:client]
    if @verbose
      if client
        puts "send to #{ip}:#{port} " \
             "client(id=#{client.id} " \
             "token=#{client.token} " \
             "name=#{client.player.name} port=#{client.addr.port})"
      else
        puts "send to #{ip}:#{port}"
      end
    end
    @s.send(data, 0, ip, port)

    puts Packet.new(data, '>') if @verbose || opts[:test]
  end
end
