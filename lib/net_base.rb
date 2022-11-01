class NetBase
  attr_accessor :client_token, :server_token, :ack

  def initialize
    @ip = nil
    @port = nil
    @s = nil
    @ack = 0
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
    header_bits =
      '00' + # unused flags?           # ff
      flags_bits +                     #    ffff
      @ack.to_s(2).rjust(10, '0') +    #        aa aaaa aaaa
      num_chunks.to_s(2).rjust(8, '0') # NNNN NNNN

    header = header_bits.chars.groups_of(8).map do |eight_bits|
      eight_bits.join('').to_i(2)
    end

    header = header + str_bytes(@server_token)
    data = (header + payload).pack('C*')
    @s.send(data, 0, @ip, @port)

    if @verbose || flags[:test]
      p = Packet.new(data, '>')
      puts p.to_s
    end
  end
end

