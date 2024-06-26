# frozen_string_literal: true

require_relative 'array'

SANITIZE = 1
SANITIZE_CC = 2
SKIP_START_WHITESPACES = 4

class Packer
  # Format: ESDDDDDD EDDDDDDD EDD... Extended, Data, Sign
  # @return [Array<int>]
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
    # ^^^    ^ ^^    ^
    # ||\   /  | \   /
    # || \ / not  \ /
    # ||  \ extended
    # ||   \      /
    # ||    \    /
    # ||     \  /
    # ||      \/
    # ||      /\
    # ||     /  \
    # ||    /    \
    # || 0000001 000000
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
    first = "1#{sign}#{num_bits[-6..]}"

    num_bits = num_bits[0..-7]
    bytes = num_bits.chars.groups_of(7).map do |seven_bits|
      # mark all as extended
      "1#{seven_bits.join.rjust(7, '0')}"
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
  attr_reader :prev, :data, :parsed

  def initialize(data)
    @data = data
    @prev = [] # all the data already unpacked
    @parsed = []
    # TODO: delete parsed or document it with examples
    # @parsed.push({ type: 'string', value: str, raw:, len:, pos: })
    @red_bytes = 0
    # { type: 'int', value: 1, raw: "\x01", len: 1, pos: 0 }
    if data.instance_of?(String)
      @data = data.unpack('C*')
    elsif data.instance_of?(Array)
      @data = data
    else
      raise 'Error: Unpacker expects array of integers or byte string'
    end
  end

  def str_sanitize(str)
    letters = str.chars
    letters.map! do |c|
      c.ord < 32 && c != "\r" && c != "\n" && c != "\t" ? ' ' : c
    end
    letters.join
  end

  def str_sanitize_cc(str)
    letters = str.chars
    letters.map! do |c|
      c.ord < 32 ? ' ' : c
    end
    letters.join
  end

  def get_string(sanitize = SANITIZE)
    return nil if @data.nil?

    str = ''
    raw = []
    len = 0
    pos = @red_bytes
    @data.each_with_index do |byte, index|
      @prev.push(byte)
      raw.push(raw)
      @red_bytes += 1
      len += 1
      if byte.zero?
        @data = index == @data.length - 1 ? nil : @data[(index + 1)..]
        str = str_sanitize(str) unless (sanitize & SANITIZE).zero?
        str = str_sanitize_cc(str) unless (sanitize & SANITIZE_CC).zero?
        @parsed.push({ type: 'string', value: str, raw:, len:, pos: })
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
    return nil if @data.empty?

    # TODO: make this more performant
    #       it should not read in ALL bytes
    #       of the WHOLE packed data
    #       it should be max 4 bytes
    #       because bigger ints are not sent anyways
    bytes = @data.map { |byte| byte.to_s(2).rjust(8, '0') }
    first = bytes[0]

    sign = first[1]
    bits = []
    parsed = { type: 'int' }

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
      @prev += @data[0...consumed]
      parsed[:raw] = @data[0...consumed]
      parsed[:len] = consumed
      parsed[:pos] = @red_bytes
      @red_bytes += consumed
      @data = @data[consumed..]
    else # single byte
      bits = [first[2..]]
      @prev.push(@data[0])
      parsed[:raw] = [@data[0]]
      parsed[:len] = 1
      parsed[:pos] = @red_bytes
      @red_bytes += 1
      @data = @data[1..]
    end
    num = bits.join.to_i(2)
    parsed[:value] = sign == '1' ? -(num + 1) : num
    @parsed.push(parsed)
    parsed[:value]
  end

  def get_raw(size = -1)
    len = size == -1 ? @data.size : size
    @prev += @data[...len]
    pos = @red_bytes
    @red_bytes += len
    @parsed.push({ type: 'raw', value: @data[...len], raw: @data[...len], len:, pos: })
    # TODO: error if size exceeds @data.size
    @data.shift(len)
  end
end
