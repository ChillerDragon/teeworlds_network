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

  context 'Unpack strings sanitize (default)' do
    it 'Should replace bytes lower than 32 with spaces' do
      u = Unpacker.new([0x02, 0x41, 0x41, 0x00, 0x1F, 0x42, 0x42, 0x00])
      expect(u.get_string).to eq(' AA')
      expect(u.get_string).to eq(' BB')
      expect(u.get_string).to eq(nil)
    end
    it 'Should keep \r, \n and \t' do
      u = Unpacker.new(["\r".ord, 0x41, 0x41, 0x00, "\n".ord, 0x42, "\t".ord, 0x42, 0x00])
      expect(u.get_string).to eq("\rAA")
      expect(u.get_string).to eq("\nB\tB")
      expect(u.get_string).to eq(nil)
    end
  end

  context 'Unpack strings sanitize cc' do
    it 'Should replace bytes lower than 32 with spaces' do
      u = Unpacker.new([0x02, 0x41, 0x41, 0x00, 0x1F, 0x42, 0x42, 0x00])
      expect(u.get_string).to eq(' AA')
      expect(u.get_string).to eq(' BB')
      expect(u.get_string).to eq(nil)
    end
    it 'Should NOT keep \r, \n and \t' do
      u = Unpacker.new(["\r".ord, 0x41, 0x41, 0x00, "\n".ord, 0x42, "\t".ord, 0x42, 0x00])
      expect(u.get_string(SANITIZE_CC)).to eq(' AA')
      expect(u.get_string(SANITIZE_CC)).to eq(' B B')
      expect(u.get_string(SANITIZE_CC)).to eq(nil)
    end
  end

  context 'Unpack single byte integers' do
    it 'Should unpack positive integers' do
      u = Unpacker.new([0x01, 0x02])
      expect(u.get_int).to eq(1)
      expect(u.get_int).to eq(2)
    end

    it 'Should unpack negative integers' do
      u = Unpacker.new([0x40, 0x41, 0x42])
      # 0x40 => 1000 0000
      #         ^^      ^
      #  negative\      /
      #           \    /
      #             0
      #
      # There is no -0 so it will be -1
      expect(u.get_int).to eq(-1)
      expect(u.get_int).to eq(-2)
      expect(u.get_int).to eq(-3)
    end

    it 'Should unpack positive and negative integers' do
      u = Unpacker.new([0x01, 0x02, 0x03, 0x40, 0x41, 0x42])
      expect(u.get_int).to eq(1)
      expect(u.get_int).to eq(2)
      expect(u.get_int).to eq(3)
      expect(u.get_int).to eq(-1)
      expect(u.get_int).to eq(-2)
      expect(u.get_int).to eq(-3)
    end

    it 'Should pack and unpack and match from 0 to 63' do
      64.times do |i|
        u = Unpacker.new(Packer.pack_int(i))
        expect(u.get_int).to eq(i)
      end
    end

    # https://github.com/ddnet/ddnet/pull/6015
    it 'Should unpack the same as ddnet C++ tests -3..3' do
      expect(Packer.pack_int(1).first.to_s(2).rjust(8, '0')).to eq('00000001')
      expect(Packer.pack_int(2).first.to_s(2).rjust(8, '0')).to eq('00000010')
      expect(Packer.pack_int(3).first.to_s(2).rjust(8, '0')).to eq('00000011')

      expect(Packer.pack_int(-1).first.to_s(2).rjust(8, '0')).to eq('01000000')
      expect(Packer.pack_int(-2).first.to_s(2).rjust(8, '0')).to eq('01000001')
      expect(Packer.pack_int(-3).first.to_s(2).rjust(8, '0')).to eq('01000010')

      u = Unpacker.new(['00000001'.to_i(2)])
      expect(u.get_int).to eq(1)
      u = Unpacker.new(['00000010'.to_i(2)])
      expect(u.get_int).to eq(2)
      u = Unpacker.new(['00000011'.to_i(2)])
      expect(u.get_int).to eq(3)

      u = Unpacker.new(['01000000'.to_i(2)])
      expect(u.get_int).to eq(-1)
    end

    it 'Should pack and unpack and match from -3 to 3' do
      (-3..3).each do |i|
        u = Unpacker.new(Packer.pack_int(i))
        expect(u.get_int).to eq(i)
      end
    end

    it 'Should pack and unpack and match from -63 to 63' do
      (-63..63).each do |i|
        u = Unpacker.new(Packer.pack_int(i))
        expect(u.get_int).to eq(i)
      end
    end

    it 'Should unpack 0000 0001 to 1' do
      u = Unpacker.new(['00000001'.to_i(2)])
      expect(u.get_int).to eq(1)
    end
  end

  context 'Unpack multi byte integers' do
    it 'Should pack and unpack and match from 0 to 128' do
      129.times do |i|
        u = Unpacker.new(Packer.pack_int(i))
        expect(u.get_int).to eq(i)
      end
    end

    it 'Should unpack 0xFF 0x01 to -128 (match tw traffic)' do
      u = Unpacker.new([0xFF, 0x01])
      expect(u.get_int).to eq(-128)
    end

    it 'Should pack and unpack and match from -128 to 128' do
      (-128..128).each do |i|
        u = Unpacker.new(Packer.pack_int(i))
        expect(u.get_int).to eq(i)
      end
    end

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

    it 'Should unpack 1100 0000  0000 0001 to -65' do
      u = Unpacker.new(['11000000'.to_i(2), '00000001'.to_i(2)])
      expect(u.get_int).to eq(-65)
    end
  end
end
