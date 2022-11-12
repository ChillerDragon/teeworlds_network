# frozen_string_literal: true

require_relative '../lib/chunk'

describe 'NetChunk', :net_chunk do
  context 'Create vital header' do
    it 'Should set the vital flag' do
      expect(NetChunk.create_header(vital: true, size: 20, seq: 5)).to eq([64, 20, 5])
    end
  end
end

describe 'BigChungusTheChunkGetter', :chunk_getter do
  context 'Single chunk' do
    it 'Should count one motd chunk correctly' do
      # handcrafted fake packet
      # one empty motd chunks
      data = [
        0x40, 0x02, 0x02, 0x02, 0x00
      ].pack('C*')
      chunks = BigChungusTheChunkGetter.get_chunks(data)
      expect(chunks.size).to eq(1)
    end
  end

  context 'Multiple chunks' do
    it 'Should parse two motd chunks correctly' do
      # handcrafted fake packet
      # two empty motd chunks
      data = [
        0x40, 0x02, 0x02, 0x02, 0x00,
        0x40, 0x02, 0x02, 0x02, 0x00
      ].pack('C*')
      chunks = BigChungusTheChunkGetter.get_chunks(data)
      expect(chunks.size).to eq(2)
      expect(chunks[0].msg).to eq(NETMSGTYPE_SV_MOTD)
      expect(chunks[1].msg).to eq(NETMSGTYPE_SV_MOTD)
      expect(chunks[0].sys).to eq(false)
    end

    it 'Should parse motd + server settings' do
      # actual packet server sends
      data = [
        0x40, 0x02, 0x02, 0x02, 0x00, # motd
        0x40, 0x07, 0x03, 0x22, 0x01, 0x00, 0x01, 0x00, 0x01, 0x08, # server settings
        0x40, 0x01, 0x04, 0x0b # ready
      ].pack('C*')
      chunks = BigChungusTheChunkGetter.get_chunks(data)
      expect(chunks.size).to eq(3)
      expect(chunks[0].msg).to eq(NETMSGTYPE_SV_MOTD)
      expect(chunks[1].msg).to eq(NETMSGTYPE_SV_SERVERSETTINGS)
    end

    it 'Should parse map change packet' do
      # actual mapchange the server sends
      map_change = [
        0x40, 0x32, 0x01, 0x05, 0x62, 0x72, 0x69, 0x64, 0x67, 0x65, 0x00,
        0xee, 0xcb, 0xd0, 0xd7, 0x02, 0x9c, 0x0e, 0x08, 0xa8, 0x15, 0x1a, 0xb3, 0xbb, 0xb1, 0xd4, 0x04,
        0x75, 0x68, 0xec, 0xe3, 0x41, 0x6e, 0x83, 0x20, 0xaf, 0x97, 0x0f, 0x49, 0xbe, 0x4f, 0x3c, 0x61,
        0x04, 0xf4, 0xbe, 0x60, 0xd2, 0x87, 0x39, 0x91, 0x59, 0xab
      ].pack('C*')
      chunks = BigChungusTheChunkGetter.get_chunks(map_change)
      expect(chunks.size).to eq(1)
      expect(chunks[0].sys).to eq(true)
    end
  end
end
