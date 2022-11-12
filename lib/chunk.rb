# frozen_string_literal: true

require_relative 'array'
require_relative 'network'
require_relative 'bytes'

class NetChunk
  attr_reader :next, :data, :msg, :sys, :flags

  @@sent_vital_chunks = 0

  def initialize(data)
    @next = nil
    @flags = {}
    @size = 0
    parse_header(data[0..2])
    chunk_end = CHUNK_HEADER_SIZE + @size
    # puts "data[0]: " + str_hex(data[0])
    @data = data[CHUNK_HEADER_SIZE...chunk_end]
    @msg = @data[0].unpack1('C*')
    @sys = @msg & 1 == 1
    @msg >>= 1
    @next = data[chunk_end..] if data.size > chunk_end
  end

  def self.reset
    @@sent_vital_chunks = 0
  end

  def to_s
    "NetChunk\n" \
      "  msg=#{msg} sys=#{sys}\n" \
      "  #{@flags}\n" \
      "  data: #{str_hex(data)}"
  end

  def self._create_non_vital_header(data = { size: 0 })
    flag_bits = '00'
    unused_bits = '00'

    size_bits = data[:size].to_s(2).rjust(12, '0')
    header_bits =
      flag_bits +
      size_bits[0..5] +
      unused_bits +
      size_bits[6..]
    header_bits.chars.groups_of(8).map do |eigth_bits|
      eigth_bits.join.to_i(2)
    end
  end

  ##
  # Create int array ready to be send over the network
  #
  # Given the flags hash (vital/resend)
  # the size
  # the sequence number
  #
  # It will create a 3 byte chunk header
  # represented as an Array of 3 integers
  def self.create_header(opts = { resend: false, vital: false, size: nil, seq: nil })
    raise 'Chunk.create_header :size option can not be nil' if opts[:size].nil?
    return _create_non_vital_header(opts) unless opts[:vital]

    @@sent_vital_chunks += 1
    seq = opts[:seq].nil? ? @@sent_vital_chunks : opts[:seq]

    flag_bits = '00'.dup
    flag_bits[0] = opts[:resend] ? '1' : '0'
    flag_bits[1] = opts[:vital] ? '1' : '0'

    size_bits = opts[:size].to_s(2).rjust(12, '0')
    # size_bits[0..5]
    # size_bits[6..]

    seq_bits = seq.to_s(2).rjust(10, '0')
    # seq_bits[0..1]
    # seq_bits[2..]

    # The vital chunk header is 3 bytes
    # containing flags, size and sequence
    # in the following format
    #
    # f=flag
    # s=size
    # q=sequence
    #
    # ffss ssss qqss ssss qqqq qqqq
    header_bits =
      flag_bits +
      size_bits[0..5] +
      seq_bits[0..1] +
      size_bits[6..] +
      seq_bits[2..]
    header_bits.chars.groups_of(8).map do |eigth_bits|
      eigth_bits.join.to_i(2)
    end
  end

  def parse_header(data)
    # flags
    flags = data[0].unpack1('B*')
    flags = flags[0..1]
    @flags[:resend] = flags[0] == '1'
    @flags[:vital] = flags[1] == '1'

    # size
    size = data[0..1].unpack1('B*')
    size_bytes = size.chars.groups_of(8)
    # trim first 2 bits of both bytes
    # Size: 2 bytes (..00 0000 ..00 0010)
    size_bytes.map! { |b| b[2..].join }
    @size = size_bytes.join.to_i(2)

    # sequence number
    # in da third byte but who needs seq?!
  end

  def flags_vital
    @flags[:vital]
  end

  def flags_resend
    @flags[:resend]
  end
end

MAX_NUM_CHUNKS = 1024

class BigChungusTheChunkGetter
  def self.get_chunks(data)
    chunks = []
    chunk = NetChunk.new(data)
    chunks.push(chunk)
    while chunk.next
      chunk = NetChunk.new(chunk.next)
      chunks.push(chunk)
      next unless chunks.size > MAX_NUM_CHUNKS

      # inf loop guard case
      puts 'Warning: abort due to max num chunks bein reached'
      break
    end
    chunks
  end
end
