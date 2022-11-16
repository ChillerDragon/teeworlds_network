# frozen_string_literal: true

require_relative 'array'
require_relative 'string'

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

COL_LEN = 9

# TODO: make this a gem?!
#
# opts
# legend: :long
# legend: :short
# legend: :inline
def hexdump_lines(data, width = 2, notes = [], opts = { legend: :long })
  byte_groups = data.unpack1('H*').scan(/../).groups_of(4)
  lines = []
  hex = ''
  ascii = ''
  w = 0
  byte = 0
  legend = []
  notes.each do |info|
    color = info.first
    raise "Invalid color '#{color}' valid ones: #{AVAILABLE_COLORS}" unless AVAILABLE_COLORS.include? color

    legend.push([color, info.last.send(color)])
  end
  unless legend.empty?
    case opts[:legend]
    when :long
      legend.each do |leg|
        lines.push("#{leg.first}: #{leg.last}".send(leg.first))
      end
    when :short
      lines.push(legend.map(&:last).join(' '))
    end
  end
  byte_groups.each do |byte_group|
    hex += '  ' unless hex.empty?
    ascii += data_to_ascii(str_bytes(byte_group.join).pack('C*'))
    w += 1
    note = ''
    colors = 0
    notes.each do |info|
      color = info.first
      # p color
      # p info
      from = info[1]
      to = info[1] + (info[2] - 1)

      if from > byte + 3
        # puts "a"
        next
      end
      if to < byte
        # puts "to: #{to} < byte: #{byte}"
        next
      end

      note += " #{info[3]}".send(color) if opts[:legend] == :inline

      from -= byte
      to -= byte
      from = 0 if from.negative?
      to = 3 if to > 3

      # puts "from: #{from} to: #{to}"
      (from..to).each do |i|
        next if byte_group[i].nil?

        byte_group[i] = byte_group[i].send(color)
        colors += 1
      end
    end
    byte += 4
    hex += byte_group.join(' ')
    next unless w >= width

    w = 0
    hex_pad = hex.ljust((width * 4 * 3) + (colors * COL_LEN), ' ')
    ascii_pad = ascii.ljust(width * 4)
    lines.push("#{hex_pad}     #{ascii_pad}#{note}")
    hex = ''
    ascii = ''
  end
  lines.push("#{hex_pad}     #{ascii_pad}#{note}") unless hex.empty?
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

def todo_make_this_a_unit_test
  notes = [
    [:red, 0, 1, 'foo'],
    [:green, 1, 1, 'bar'],
    [:yellow, 2, 1, 'baz'],
    [:pink, 3, 1, 'bang'],
    [:green, 4, 1, 'bär'],
    [:yellow, 6, 6, 'yee']
  ]

  hexdump_lines("\x01\x41\x02\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\xef", 40, notes).each do |l|
    puts l
  end

  hexdump_lines("\x01\x41\x02\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\xef", 40, notes, legend: long).each do |l|
    puts l
  end

  # should not crash when annotating bytes out of range
  hexdump_lines("\x01\x41", 40, notes, legend: :long).each do |l|
    puts l
  end
end
