# frozen_string_literal: true

require_relative 'array'

# turn byte array into hex string
def str_hex(data)
  data.unpack1('H*').scan(/../).join(' ').upcase
end

def data_to_ascii(data)
  ascii = ''
  data.unpack('C*').each do |c|
    ascii += c < 32 || c > 126 ? '.' : c.chr
  end
  ascii
end

def hexdump_lines(data, width = 2)
  byte_groups = data.unpack1('H*').scan(/../).groups_of(4)
  lines = []
  hex = ''
  ascii = ''
  w = 0
  byte_groups.each do |byte_group|
    hex += '  ' unless hex.empty?
    hex += byte_group.join(' ')
    ascii += data_to_ascii(str_bytes(byte_group.join).pack('C*'))
    w += 1
    next unless w >= width

    w = 0
    lines.push("#{hex}     #{ascii}")
    hex = ''
    ascii = ''
  end
  lines.push("#{hex}     #{ascii}") unless hex.empty?
  lines
end

# turn hex string to byte array
def str_bytes(str)
  str.scan(/../).map { |b| b.to_i(16) }
end

def bytes_to_str(data)
  data.unpack('H*').join
end

# TODO: remove?
def get_byte(data, start = 0, num = 1)
  data[start...(start + num)].unpack('H*').join.upcase
end
