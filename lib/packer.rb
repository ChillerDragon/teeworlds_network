require_relative 'array'

class Packer
  # Format: ESDDDDDD EDDDDDDD EDD... Extended, Data, Sign
  def self.pack_int(num)
    # the first byte can fit 6 bits
    # because the first two bits are extended and sign
    # so if you have a number bigger than 63
    # it needs two bytes
    # which are also least significant byte first etc
    # so we do not support that YET
    #
    # the first too big number 64 is represented as those bits
    # 10000000 00000001
    # ^^^    ^ ^      ^
    # ||\   /   \    /
    # || \ /     \  /
    # ||  \       \/
    # ||   \      /
    # ||    \    /
    # ||     \  /
    # ||      \/
    # ||      /\
    # ||     /  \
    # ||    /    \
    # || 00000001 000000
    # ||       |
    # ||       v
    # ||       64
    # ||
    # |positive
    # extended
    sign = '0'
    if num.negative?
      sign = '1'
      num += 1
    end
    num = num.abs
    if num > 63 || num < -63
      return self.pack_big_int(sign, num)
    end
    ext = '0'
    bits = ext + sign + num.to_s(2).rjust(6, '0')
    [bits.to_i(2)]
  end

  def self.pack_big_int(sign, num)
    num_bits = num.to_s(2)
    first = '1' + sign + num_bits[-6..]

    num_bits = num_bits[0..-7]
    bytes = []
    num_bits.chars.groups_of(7).each do |seven_bits|
      # mark all as extended
      bytes << '1' + seven_bits.join('').rjust(7, '0')
    end
    # least significant first
    bytes = bytes.reverse
    # mark last byte as unextended
    bytes[-1][0] = '0'
    ([first] + bytes).map { |b| b.to_i(2) }
  end

  def self.pack_str(str)
    str.chars.map(&:ord) + [0x00]
  end

  def initialize(data)
    @data = data
  end

  def get_string()
    return nil if @data.nil?

    str = ''
    @data.each_with_index do |byte, index|
      if byte == 0x00
        if index == @data.length - 1
          @data = nil
        else
          @data = @data[(index + 1)..]
        end
        return str
      end
      str += byte.chr
    end
    # raise "get_string() failed to find null terminator"
    # return empty string in case of error
    ''
  end

  def get_int()
    return nil if @data.nil?

    # todo: make this more performant
    #       it should not read in ALL bytes
    #       of the WHOLE packed data
    #       it should be max 4 bytes
    #       because bigger ints are not sent anyways
    bytes = @data.chars.groups_of(8)
    first = bytes[0]
    other = bytes[1..]

    sign = first[1] == '1' ? -1 : 1

    bits = ''

    # extended
    if first[0] == '1'
      bytes.each do |eigth_bits|
      end
    else # single byte
      bits = first[2..].join('')
    end
    bits.to_i(2) * sign
  end
end

def todo_make_this_rspec_test
  # single byte int
  p Packer.pack_int(1) == [1]
  p Packer.pack_int(3) == [3]
  p Packer.pack_int(16) == [16]
  p Packer.pack_int(63) == [63]

  # negative single byte
  p Packer.pack_int(-1) == [64]
  p Packer.pack_int(-2) == [65]

  # multi byte int
  p Packer.pack_int(64) == [128, 1]
  p Packer.pack_int(99999999999999999) == [191, 131, 255, 147, 246, 194, 215, 232, 88]

  # string
  p Packer.pack_str("A") == [65, 0]
end

def todo_also_rspec_unpacker
  p = Packer.new([0x41, 0x41, 0x00, 0x42, 0x42, 0x00])
  p p.get_string() == "AA"
  p p.get_string() == "BB"
  p p.get_string() == nil
end

todo_also_rspec_unpacker

