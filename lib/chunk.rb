require_relative 'array'
require_relative 'network'
require_relative 'bytes'

class NetChunk
  attr_reader :next, :data, :msg, :sys

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

# todo_make_this_an_rspec_test

