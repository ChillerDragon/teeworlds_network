# frozen_string_literal: true

require_relative 'snapshot'

# should be merged with SnapItemBase
class SnapItem
  # @param type [Integer] type of the item for example 5 is obj_flag
  # @param id [Integer] id of said item for characters thats the ClientID
  # @param fields [Array] array of uncompressed integers
  #                       for example [0, 0, 1] for obj_flag
  #                       would set
  #                       m_X = 0
  #                       m_Y = 0
  #                       m_Team = 1
  def initialize(type, id, size, fields)
    @type = type
    @id = id
    @size = size
    @fields = fields
  end

  # basically to_network
  # tee int array that will be sent over
  # the wire
  def to_a
    Packer.pack_int(@type) +
      Packer.pack_int(@id) +
      fields.map { |field| Packer.pack_int(field) }
  end
end

class SnapshotBuilder
  def initialize
    @data_size = 0
    @num_items = 0
    @items = []
  end

  ##
  # insert new snap item into the snap
  #
  # https://chillerdragon.github.io/teeworlds-protocol/07/snap_items.html
  #
  # @param type [Integer] type of the item for example 5 is obj_flag
  # @param id [Integer] id of said item for characters thats the ClientID
  # @param fields [Array] array of uncompressed integers
  #                       for example [0, 0, 1] for obj_flag
  #                       would set
  #                       m_X = 0
  #                       m_Y = 0
  #                       m_Team = 1
  def new_item(type, id, size, fields)
    item = SnapItem.new(type, id, size, fields)
    @items.push(item)
  end

  # @return [Snapshot]
  def finish
    Snapshot.new
  end
end
