require_relative 'array'
require_relative 'network'
require_relative 'bytes'

class NetChunk
  attr_reader :next, :data, :msg, :sys, :flags
  @@sent_vital_chunks = 4 # BIG TODO: SEND READY AND SHIT WITH PROPER HEADER

  def initialize(data)
    @next = nil
    @flags = {}
    @size = 0
    parse_header(data[0..2])
    chunk_end = CHUNK_HEADER_SIZE + @size
    # puts "data[0]: " + str_hex(data[0])
    @data = data[CHUNK_HEADER_SIZE...chunk_end]
    @msg = @data[0].unpack("C*").first
    @sys = @msg & 1 == 1 ? true : false
    @msg >>= 1
    @next = data[chunk_end..] if data.size > chunk_end
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
  def self.create_vital_header(flags, size, seq = nil)
    @@sent_vital_chunks += 1
    if seq.nil?
      seq = @@sent_vital_chunks
    end

    flag_bits = '00'
    flag_bits[0] = flags[:resend] ? '1' : '0'
    flag_bits[1] = flags[:vital] ? '1' : '0'

    size_bits = size.to_s(2).rjust(12, '0')
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
      eigth_bits.join('').to_i(2)
    end
  end

  def parse_header(data)
    # flags
    flags = data[0].unpack("B*").first
    flags = flags[0..1]
    @flags[:resend] = flags[0] == "1"
    @flags[:vital] = flags[1] == "1"

    # size
    size = data[0..1].unpack("B*").first
    size_bytes = size.chars.groups_of(8)
    # trim first 2 bits of both bytes
    # Size: 2 bytes (..00 0000 ..00 0010)
    size_bytes.map! {|b| b[2..].join('') }
    @size = size_bytes.join('').to_i(2)

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
      if chunks.size > MAX_NUM_CHUNKS
        # inf loop guard case
        puts "Warning: abort due to max num chunks bein reached"
        break
      end
    end
    chunks
  end
end

def todo_make_this_an_rspec_test
  # handcrafted fake packet
  # two empty motd chunks
  data = [
    0x40, 0x02, 0x02, 0x02, 0x00,
    0x40, 0x02, 0x02, 0x02, 0x00
  ].pack("C*")
  chunks = BigChungusTheChunkGetter.get_chunks(data)
  p chunks.size == 2
  p chunks[0].msg == NETMSGTYPE_SV_MOTD
  p chunks[1].msg == NETMSGTYPE_SV_MOTD
  p chunks[0].sys == false

  # actual packet server sends
  data = [
    0x40, 0x02, 0x02, 0x02, 0x00, # motd
    0x40, 0x07, 0x03, 0x22, 0x01, 0x00, 0x01, 0x00, 0x01, 0x08, # server settings
    0x40, 0x01, 0x04, 0x0b # ready
  ].pack("C*")
  chunks = BigChungusTheChunkGetter.get_chunks(data)
  p chunks.size == 3
  p chunks[0].msg == NETMSGTYPE_SV_MOTD
  p chunks[1].msg == NETMSGTYPE_SV_SERVERSETTINGS

  # actual mapchange the server sends
  map_change = [
    0x40, 0x32, 0x01, 0x05, 0x62, 0x72, 0x69, 0x64, 0x67, 0x65, 0x00,
    0xee, 0xcb, 0xd0, 0xd7, 0x02, 0x9c, 0x0e, 0x08, 0xa8, 0x15, 0x1a, 0xb3, 0xbb, 0xb1, 0xd4, 0x04,
    0x75, 0x68, 0xec, 0xe3, 0x41, 0x6e, 0x83, 0x20, 0xaf, 0x97, 0x0f, 0x49, 0xbe, 0x4f, 0x3c, 0x61,
    0x04, 0xf4, 0xbe, 0x60, 0xd2, 0x87, 0x39, 0x91, 0x59, 0xab
  ].pack("C*")
  chunks = BigChungusTheChunkGetter.get_chunks(map_change)
  p chunks.size == 1
  p chunks[0].sys == true
end

def test2
  p NetChunk.create_vital_header({vital: true}, 20, 5) == [64, 20, 5]
end

