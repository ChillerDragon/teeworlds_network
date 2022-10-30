require 'huffman_tw'

# Class holding the parsed packet data
class Packet
  attr_reader :flags, :payload

  def initialize(data, prefix = '')
    # @data and @payload
    # are strings representing the raw bytes
    #
    # @prefix is a String that will be displayed
    #         when printing the packet
    #         use '>' and '<' for example to indicate
    #         network direction (client/server)
    @prefix = prefix
    @huffman = Huffman.new
    @flags = {}
    @data = data
    flags_byte = @data[0].unpack("B*")
    parse_flags(flags_byte.first[2..5])
    @payload = @data[PACKET_HEADER_SIZE..]
    if flags_compressed
      @payload = @huffman.decompress(@payload.unpack("C*"))
      @payload = @payload.pack("C*")
    end
  end

  def annotate_first_row(bytes)
    header = bytes[0..2].join(' ').yellow
    token = bytes[3..6].join(' ').green
    payload = bytes[7..].join(' ')
    puts @prefix + "  data: #{[header, token, payload].join(' ')}"
    print @prefix + "        "
    print "header".ljust(3 * 3, ' ').yellow
    print "token".ljust(4 * 3, ' ').green
    puts "data"
  end

  def to_s()
    puts @prefix + "Packet"
    puts @prefix + "  flags: #{@flags}"
    bytes = str_hex(@data).split(' ')
    # todo: check terminal size?
    max_width = 14
    rows = bytes.groups_of(max_width)
    annotate_first_row(rows.first)
    rows[1..].each do |row|
      print @prefix + "        "
      puts row.join(' ')
    end
    puts ""
  end

  def parse_flags(four_bit_str)
    # takes a 4 character string
    # representing the middle of the first byte sent
    # in binary representation
    #
    # and creates a hash out of it
    @flags = {}
    @flags[:connection] = four_bit_str[0] == '1'
    @flags[:compressed] = four_bit_str[1] == '1'
    @flags[:resend] = four_bit_str[2] == '1'
    @flags[:control] = four_bit_str[3] == '1'
    @flags
  end

  def flags_compressed()
    @flags[:compressed]
  end

  def flags_connless()
    @flags[:connection] == false
  end

  def flags_control()
    @flags[:control]
  end
end

