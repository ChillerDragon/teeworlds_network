# frozen_string_literal: true

require_relative '../lib/packer'

describe 'Packer', :packer do
  context 'Pack strings' do
    it 'Should pack a single string' do
      expect(Packer.pack_str('A')).to eq([65, 0])
    end
  end

  context 'Pack single byte integers' do
    it 'Should pack positive' do
      expect(Packer.pack_int(1)).to eq([1])
      expect(Packer.pack_int(3)).to eq([3])
      expect(Packer.pack_int(16)).to eq([16])
      expect(Packer.pack_int(63)).to eq([63])
    end

    it 'Should pack negative' do
      expect(Packer.pack_int(-1)).to eq([64])
      expect(Packer.pack_int(-2)).to eq([65])
    end

    it 'Should pack negative match binary' do
      expect(Packer.pack_int(-1).first.to_s(2).rjust(8, '0')).to eq('01000000')
      expect(Packer.pack_int(-2).first.to_s(2).rjust(8, '0')).to eq('01000001')
      expect(Packer.pack_int(-3).first.to_s(2).rjust(8, '0')).to eq('01000010')
      expect(Packer.pack_int(-4).first.to_s(2).rjust(8, '0')).to eq('01000011')
    end

    # https://github.com/ddnet/ddnet/pull/6015
    it 'Should pack the same as ddnet C++ tests -3..3' do
      expect(Packer.pack_int(1).first.to_s(2).rjust(8, '0')).to eq('00000001')
      expect(Packer.pack_int(2).first.to_s(2).rjust(8, '0')).to eq('00000010')
      expect(Packer.pack_int(3).first.to_s(2).rjust(8, '0')).to eq('00000011')

      expect(Packer.pack_int(-1).first.to_s(2).rjust(8, '0')).to eq('01000000')
      expect(Packer.pack_int(-2).first.to_s(2).rjust(8, '0')).to eq('01000001')
      expect(Packer.pack_int(-3).first.to_s(2).rjust(8, '0')).to eq('01000010')
    end
  end

  context 'Pack multi byte integers' do
    it 'Should pack positive' do
      expect(Packer.pack_int(64).map { |e| e.to_s(2).rjust(8, '0') }).to eq(%w[10000000 00000001])
      expect(Packer.pack_int(64)).to eq([128, 1])
    end

    it 'Should pack negative' do
      expect(Packer.pack_int(-65).map { |e| e.to_s(2).rjust(8, '0') }).to eq(%w[11000000 00000001])
    end

    it 'Should pack large numbers' do
      expect(Packer.pack_int(99_999_999_999_999_999)).to eq([191, 131, 255, 147, 246, 194, 215, 232, 88])
    end

    it 'Should pack -128 to 1111 1111 0000 0001 (match tw traffic)' do
      expect(Packer.pack_int(-128).map { |b| b.to_s(2).rjust(8, '0') }).to eq(%w[11111111 00000001])
    end

    it 'Should pack -128 to 0xFF 0x01 (match tw traffic)' do
      expect(Packer.pack_int(-128)).to eq([0xFF, 0x01])
    end
  end
end
