# frozen_string_literal: true

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
