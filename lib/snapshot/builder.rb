# frozen_string_literal: true

require_relative 'snapshot'

class SnapshotBuilder
  def initialize
    @data_size = 0
    @num_items = 0
    # @type items [Array<SnapItemBase>]
    @items = []
  end

  ##
  # insert new snap item into the snap
  #
  # https://chillerdragon.github.io/teeworlds-protocol/07/snap_items.html
  #
  # @param id [Integer] Id of the snap item. For characters that is the ClientID.
  #                     Not to be confused with the type
  # @param item [SnapItemBase] Snap item instance. Holding type and payload.
  def new_item(id, item)
    item.id = id
    @items.push(item)
  end

  # @return [Snapshot]
  def finish
    Snapshot.new(@items)
  end
end
