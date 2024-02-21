# frozen_string_literal: true

# shared by client and server
class Snapshot
  attr_accessor :game_tick, :items

  def initialize(items)
    # @type game_tick [Integer]
    @game_tick = 0
    # @type items [Array<SnapItemBase>]
    @items = items
  end

  # @return [Integer] cyclic redundancy check a checksum of all snap items
  def crc
    sum = 0
    @items.each do |item|
      sum += item.to_a.sum
    end
    sum
  end

  def to_a
    data = []
    @items.each do |item|
      data += item.to_a
    end
    data
  end
end
