# frozen_string_literal: true

require_relative '../lib/bytes'

describe 'Bytes', :bytes do
  context '#str_hex' do
    it 'Should format "\xFF" to "FF"' do
      expect(str_hex("\xFF")).to eq('FF')
    end
    it 'Should format "\x01" to "01"' do
      expect(str_hex("\x01")).to eq('01')
    end
    it 'Should format "\x01\x02" to "01 02"' do
      expect(str_hex("\x01\x02")).to eq('01 02')
    end
  end
  context '#str_bytes' do
    it 'Should format "ff" to [255]' do
      expect(str_bytes('ff')).to eq([255])
    end
    it 'Should format "FF" to [255]' do
      expect(str_bytes('FF')).to eq([255])
    end
    it 'Should format "01" to [1]' do
      expect(str_bytes('01')).to eq([1])
    end
    it 'Should format "0101" to [1, 1]' do
      expect(str_bytes('0101')).to eq([1, 1])
    end
  end
  context '#bytes_to_str' do
    it 'Should format "\xff" to "ff"' do
      expect(bytes_to_str("\xff")).to eq('ff')
    end
    it 'Should format "\x01" to "01"' do
      expect(bytes_to_str("\x01")).to eq('01')
    end
    it 'Should format "\x01\x01" to "0101"' do
      expect(bytes_to_str("\x01\x01")).to eq('0101')
    end
  end
end
