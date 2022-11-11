# frozen_string_literal: true

require_relative '../lib/server_info'

describe 'ServerInfo', :server_info do
  context 'Pack to network' do
    it 'Should match expected array' do
      arr = [
        0x30, 0x2E, 0x37, 0x2E, 0x35, 0x00, 0x75, 0x6E, 0x6E, 0x61,
        0x6D, 0x65, 0x64, 0x20, 0x72, 0x75, 0x62, 0x79, 0x20, 0x73,
        0x65, 0x72, 0x76, 0x65, 0x72, 0x00, 0x6C, 0x6F, 0x63, 0x61,
        0x6C, 0x68, 0x6F, 0x73, 0x74, 0x00, 0x64, 0x6D, 0x31, 0x00,
        0x64, 0x6D, 0x00, 0x00, 0x01, 0x10, 0x01, 0x80, 0x01, 0x73,
        0x61, 0x6D, 0x70, 0x6C, 0x65, 0x20, 0x70, 0x6C, 0x61, 0x79,
        0x65, 0x72, 0x00, 0x00, 0x40, 0x00, 0x00
      ]
      expect(ServerInfo.new.to_a).to eq(arr)
    end
  end
end