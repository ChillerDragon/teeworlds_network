# frozen_string_literal: true

require_relative '../packer'

##
# ClEmoticon
#
# Client -> Server
class ClEmoticon
  attr_accessor :emoticon, :name

  def initialize(hash_or_raw)
    names = [
      'oop!', # 0
      'alert', # 1
      'heart', # 2
      'tear', # 3
      '...', # 4
      'music', # 5
      'sorry', # 6
      'ghost', # 7
      'annoyed', # 8
      'angry', # 9
      'devil', # 10
      'swearing', # 11
      'zzZ', # 12
      'WTF', # 13
      'happy', # 14
      '???' # 15
    ]
    if hash_or_raw.instance_of?(Hash)
      init_hash(hash_or_raw)
    else
      init_raw(hash_or_raw)
    end
    @name = names[@emoticon]
  end

  def init_raw(data)
    u = Unpacker.new(data)
    @emoticon = u.get_int
  end

  def init_hash(attr)
    @emoticon = attr[:emoticon] || 0
  end

  def to_h
    {
      emoticon: @emoticon
    }
  end

  # basically to_network
  # int array the Client sends to the Server
  def to_a
    Packer.pack_int(@emoticon)
  end

  def to_s
    to_h
  end
end
