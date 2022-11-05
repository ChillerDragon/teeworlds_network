# frozen_string_literal: true

##
# NetBase
#
# Lowest network layer logic. Sends packets via udp.
# Also adding the teeworlds protocol packet header.
class NetBase
  attr_accessor :client_token, :server_token, :ack

  def initialize
    @ip = nil
    @port = nil
    @s = nil
    @ack = 0
    @server_token = [0xFF, 0xFF, 0xFF, 0xFF].map { |b| b.to_s(16) }.join('')
  end

  def connect(socket, ip, port)
    @s = socket
    @ip = ip
    @port = port
    @ack = 0
  end

  ##
  # Sends a packing setting the proper header for you
  #
  # @param payload [Array] The Integer list representing the data after the header
  # @param num_chunks [Integer] Amount of NetChunks in the payload
  # @param flags [Hash] Packet header flags for more details check the class +PacketFlags+
  def send_packet(payload, num_chunks = 1, flags = {})
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
    flags_bits = PacketFlags.new(flags).bits
    #          unused flags       ack                             num chunks
    #              ff ffff        aa aaaa aaaa                    NNNN NNNN
    header_bits = "00#{flags_bits}#{@ack.to_s(2).rjust(10, '0')}#{num_chunks.to_s(2).rjust(8, '0')}"

    header = header_bits.chars.groups_of(8).map do |eight_bits|
      eight_bits.join('').to_i(2)
    end

    header += str_bytes(@server_token)
    data = (header + payload).pack('C*')
    @s.send(data, 0, @ip, @port)

    puts Packet.new(data, '>').to_s if @verbose || flags[:test]
  end
end
