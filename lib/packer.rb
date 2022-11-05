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
    return pack_big_int(sign, num) if num > 63 || num < -63

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
end

class Unpacker
  def initialize(data)
    @data = data
    if data.instance_of?(String)
      @data = data.unpack('C*')
    elsif data.instance_of?(Array)
      @data = data
    else
      raise 'Error: Unpacker expects array of integers or byte string'
    end
  end

  def get_string
    return nil if @data.nil?

    str = ''
    @data.each_with_index do |byte, index|
      if byte == 0x00
        @data = if index == @data.length - 1
                  nil
                else
                  @data[(index + 1)..]
                end
        return str
      end
      str += byte.chr
    end
    # raise "get_string() failed to find null terminator"
    # return empty string in case of error
    ''
  end

  def get_int
    return nil if @data.nil?

    # TODO: make this more performant
    #       it should not read in ALL bytes
    #       of the WHOLE packed data
    #       it should be max 4 bytes
    #       because bigger ints are not sent anyways
    bytes = @data.map { |byte| byte.to_s(2).rjust(8, '0') }
    first = bytes[0]
    other = bytes[1..]

    sign = first[1] == '1' ? -1 : 1
    bits = []

    # extended
    if first[0] == '1'
      bits << first[2..]
      bytes = bytes[1..]
      consumed = 1
      bytes.each do |eigth_bits|
        bits << eigth_bits[1..]
        consumed += 1

        break if eigth_bits[0] == '0'
      end
      bits = bits.reverse
      @data = @data[consumed..]
    else # single byte
      bits = [first[2..]]
      @data = @data[1..]
    end
    bits.join('').to_i(2) * sign
  end
end

def todo_make_this_rspec_test
  # # single byte int
  # p Packer.pack_int(1) == [1]
  # p Packer.pack_int(3) == [3]
  # p Packer.pack_int(16) == [16]
  # p Packer.pack_int(63) == [63]

  # # negative single byte
  # p Packer.pack_int(-1) == [64]
  # p Packer.pack_int(-2) == [65]

  # p Packer.pack_int(-1).first.to_s(2) == '1000000'
  # p Packer.pack_int(-2).first.to_s(2) == '1000001'
  # p Packer.pack_int(-3).first.to_s(2) == '1000010'
  # p Packer.pack_int(-4).first.to_s(2) == '1000011'

  p Packer.pack_int(64).map { |e| e.to_s(2).rjust(8, '0') } == %w[10000000 00000001]
  p Packer.pack_int(-64).map { |e| e.to_s(2).rjust(8, '0') } == %w[11000000 00000000]

  # # multi byte int
  # p Packer.pack_int(64) == [128, 1]
  # p Packer.pack_int(99999999999999999) == [191, 131, 255, 147, 246, 194, 215, 232, 88]

  # # string
  # p Packer.pack_str("A") == [65, 0]
end

# todo_make_this_rspec_test

def todo_also_rspec_unpacker
  # u = Unpacker.new([0x41, 0x41, 0x00, 0x42, 0x42, 0x00])
  # p u.get_string() == "AA"
  # p u.get_string() == "BB"
  # p u.get_string() == nil

  # u = Unpacker.new([0x01, 0x02, 0x41, 0x42])
  # p u.get_int() == 1
  # p u.get_int() == 2
  # p u.get_int() == -1
  # p u.get_int() == -2

  # (-63..63).each do |i|
  #   u = Unpacker.new(Packer.pack_int(i))
  #   p u.get_int() == i
  # end

  # u = Unpacker.new([128, 1])
  # p u.get_int() == 64

  u = Unpacker.new([128, 1, 128, 1])
  p u.get_int == 64
  p u.get_int == 64
  # p u.get_int() == nil

  # (-128..128).each do |i|
  #   u = Unpacker.new(Packer.pack_int(i))
  #   p u.get_int() == i
  # end

  u = Unpacker.new(['00000001'.to_i(2)])
  p u.get_int == 1

  u = Unpacker.new(['10000000'.to_i(2), '00000001'.to_i(2)])
  p u.get_int == 64

  # TODO: should be -64
  # u = Unpacker.new(['11000000'.to_i(2), '00000000'.to_i(2)])
  # p u.get_int()
end

# todo_also_rspec_unpacker
