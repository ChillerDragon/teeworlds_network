# Class holding the parsed packet data
class Packet
  attr_reader :flags

  def initialize(data)
    @data = data
    @flags = {}
    flags_byte = data[0].unpack("B*")
    parse_flags(flags_byte.first[2..5])
  end

  def annotate_first_row(bytes)
    header = bytes[0..2].join(' ').yellow
    token = bytes[3..6].join(' ').green
    payload = bytes[7..].join(' ')
    puts "  data: #{[header, token, payload].join(' ')}"
    print "        "
    print "header".ljust(3 * 3, ' ').yellow
    print "token".ljust(4 * 3, ' ').green
    puts "data"
  end

  def to_s()
    puts "Packet"
    puts "  flags: #{@flags}"
    bytes = str_hex(@data).split(' ')
    # todo: check terminal size?
    max_width = 14
    rows = bytes.groups_of(max_width)
    annotate_first_row(rows.first)
    rows[1..].each do |row|
      print "        "
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
    @flags[:not_compressed] = four_bit_str[1] == '1'
    @flags[:no_resend] = four_bit_str[2] == '1'
    @flags[:control] = four_bit_str[3] == '1'
    @flags
  end

  def flags_connless()
    @flags[:connection] == false
  end

  def flags_control()
    @flags[:control]
  end
end

