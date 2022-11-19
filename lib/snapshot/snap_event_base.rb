# frozen_string_literal: true

require_relative '../packer'
require_relative 'snap_item_base'

class SnapEventBase < SnapItemBase
  attr_reader :x, :y

  def initialize(hash_or_raw)
    @field_names.prepend(:x)
    @field_names.prepend(:y)
    super
  end
end
