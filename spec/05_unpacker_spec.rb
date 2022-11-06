# frozen_string_literal: true

require_relative '../lib/packer'

describe 'Unpacker', :unpacker do
  context 'Unpack strings' do
    it 'Should unpack multiple strings' do
      u = Unpacker.new([0x41, 0x41, 0x00, 0x42, 0x42, 0x00])
      expect(u.get_string).to eq('AA')
      expect(u.get_string).to eq('BB')
      expect(u.get_string).to eq(nil)
    end
  end

  context 'Unpack single byte integers' do
    it 'Should unpack positive integers' do
      u = Unpacker.new([0x01, 0x02])
      expect(u.get_int).to eq(1)
      expect(u.get_int).to eq(2)
    end

    it 'Should unpack negative integers' do
      u = Unpacker.new([0x41, 0x42])
      expect(u.get_int).to eq(-1)
      expect(u.get_int).to eq(-2)
    end

    it 'Should unpack positive and negative integers' do
      u = Unpacker.new([0x01, 0x02, 0x41, 0x42])
      expect(u.get_int).to eq(1)
      expect(u.get_int).to eq(2)
      expect(u.get_int).to eq(-1)
      expect(u.get_int).to eq(-2)
    end

    it 'Should pack and unpack and match from 0 to 63' do
      (0..63).each do |i|
        u = Unpacker.new(Packer.pack_int(i))
        expect(u.get_int).to eq(i)
      end
    end

    # it 'Should pack and unpack and match from -3 to 3' do
    #   (-3..3).each do |i|
    #     u = Unpacker.new(Packer.pack_int(i))
    #     expect(u.get_int()).to eq(i)
    #   end
    # end

    # it 'Should pack and unpack and match from -63 to 63' do
    #   (-63..63).each do |i|
    #     u = Unpacker.new(Packer.pack_int(i))
    #     expect(u.get_int()).to eq(i)
    #   end
    # end

    it 'Should unpack 0000 0001 to 1' do
      u = Unpacker.new(['00000001'.to_i(2)])
      expect(u.get_int).to eq(1)
    end
  end

  context 'Unpack multi byte integers' do
    it 'Should pack and unpack and match from 0 to 128' do
      (0..128).each do |i|
        u = Unpacker.new(Packer.pack_int(i))
        expect(u.get_int).to eq(i)
      end
    end

    # it 'Should pack and unpack and match from -128 to 128' do
    #   (-128..128).each do |i|
    #     u = Unpacker.new(Packer.pack_int(i))
    #     expect(u.get_int()).to eq(i)
    #   end
    # end

    it 'Should unpack [128, 1] to 64' do
      u = Unpacker.new([128, 1])
      expect(u.get_int).to eq(64)
    end

    it 'Should unpack [128, 1, 128, 1] to [64, 64]' do
      u = Unpacker.new([128, 1, 128, 1])
      expect(u.get_int).to eq(64)
      expect(u.get_int).to eq(64)
    end

    it 'Should unpack 1000 0000  0000 0001 to 64' do
      u = Unpacker.new(['10000000'.to_i(2), '00000001'.to_i(2)])
      expect(u.get_int).to eq(64)
    end

    it 'Should unpack 1100 0001  0000 0001 to -65' do
      u = Unpacker.new(['11000001'.to_i(2), '00000001'.to_i(2)])
      expect(u.get_int).to eq(-65)
    end
  end
end
