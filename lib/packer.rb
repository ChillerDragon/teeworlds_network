class Packer
  # poor mans int packer
  # homebrew not covering
  # the full tw fancyness
  #
  # Format: ESDDDDDD EDDDDDDD EDD... Extended, Data, Sign
  def self.pack_int(num)
    if num > 63 || num < -63
      # the first byte can fit 6 bits
      # because the first two bits are extended and sign
      # so if you have a number bigger than 63
      # it needs two bytes
      # which are also least significant byte first etc
      # so we do not support that YET
      #
      # the first too big number 64 is represented as those bits
      # 10000000 00000001
      # ^^^    ^ ^      ^
      # ||\   /   \    /
      # || \ /     \  /
      # ||  \       \/
      # ||   \      /
      # ||    \    /
      # ||     \  /
      # ||      \/
      # ||      /\
      # ||     /  \
      # ||    /    \
      # || 00000001 000000
      # ||       |
      # ||       v
      # ||       64
      # ||
      # |positive
      # extended
      raise "Numbers greater than 63 are not supported yet"
    end
    sign = '0'
    if num.negative?
      sign = '1'
      num += 1
    end
    num = num.abs
    ext = '0'
    bits = ext + sign + num.to_s(2).rjust(6, '0')
    [bits.to_i(2)]
  end
end

def todo_make_this_rspec_test
  p Packer.pack_int(1) == [1]
  p Packer.pack_int(16) == [16]
  p Packer.pack_int(63) == [63]

  p Packer.pack_int(3) == [3]
  p Packer.pack_int(-1) == [64]
  p Packer.pack_int(-2) == [65]

  # todo
  # p Packer.pack_int(64) == [64]
end

