require 'huffman_tw'

class PacketFlags
  attr_reader :bits, :hash

  def initialize(data)
    @hash = {}
    @bits = ''
    if data.instance_of?(Hash)
      @bits = parse_hash(data)
      @hash = data
    elsif data.instance_of?(String)
      @hash = parse_bits(data)
      @bits = data
    else
      raise 'Flags have to be hash or string'
    end
  end

  def parse_hash(hash)
    bits = ''
    bits += hash[:connection] ? '1' : '0'
    bits += hash[:compressed] ? '1' : '0'
    bits += hash[:resend] ? '1' : '0'
    bits += hash[:control] ? '1' : '0'
    bits
  end

  def parse_bits(four_bit_str)
    # takes a 4 character string
    # representing the middle of the first byte sent
    # in binary representation
    #
    # and creates a hash out of it
    hash = {}
    hash[:connection] = four_bit_str[0] == '1'
    hash[:compressed] = four_bit_str[1] == '1'
    hash[:resend] = four_bit_str[2] == '1'
    hash[:control] = four_bit_str[3] == '1'
    hash
  end
end

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
    @data = data
    flags_byte = @data[0].unpack('B*')
    @flags = PacketFlags.new(flags_byte.first[2..5]).hash
    @payload = @data[PACKET_HEADER_SIZE..]
    if flags_compressed
      @payload = @huffman.decompress(@payload.unpack('C*'))
      @payload = @payload.pack('C*')
    end
  end

  def annotate_first_row(bytes)
    header = bytes[0..2].join(' ').yellow
    token = bytes[3..6].join(' ').green
    payload = bytes[7..].join(' ')
    puts @prefix + "  data: #{[header, token, payload].join(' ')}"
    print @prefix + '        '
    print 'header'.ljust(3 * 3, ' ').yellow
    print 'token'.ljust(4 * 3, ' ').green
    puts 'data'
  end

  def to_s
    puts @prefix + 'Packet'
    puts @prefix + "  flags: #{@flags}"
    bytes = str_hex(@data).split(' ')
    # TODO: check terminal size?
    max_width = 14
    rows = bytes.groups_of(max_width)
    annotate_first_row(rows.first)
    rows[1..].each do |row|
      print @prefix + '        '
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
