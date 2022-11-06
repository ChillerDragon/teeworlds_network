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
      expect(Packer.pack_int(-1).first.to_s(2)).to eq('1000000')
      expect(Packer.pack_int(-2).first.to_s(2)).to eq('1000001')
      expect(Packer.pack_int(-3).first.to_s(2)).to eq('1000010')
      expect(Packer.pack_int(-4).first.to_s(2)).to eq('1000011')
    end
  end

  context 'Pack multi byte integers' do
    it 'Should pack positive' do
      expect(Packer.pack_int(64).map { |e| e.to_s(2).rjust(8, '0') }).to eq(%w[10000000 00000001])
      expect(Packer.pack_int(64)).to eq([128, 1])
    end

    it 'Should pack negative' do
      expect(Packer.pack_int(-65).map { |e| e.to_s(2).rjust(8, '0') }).to eq(%w[11000001 00000001])
    end

    it 'Should pack large numbers' do
      expect(Packer.pack_int(99_999_999_999_999_999)).to eq([191, 131, 255, 147, 246, 194, 215, 232, 88])
    end
  end
end
