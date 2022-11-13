# frozen_string_literal: true

require_relative '../packer'

class GameInfo
  attr_accessor :game_flags, :score_limit, :time_limit, :match_num, :match_current

  def initialize(attr = {})
    @game_flags = attr[:game_flags] || 0
    @score_limit = attr[:score_limit] || 0
    @time_limit = attr[:time_limit] || 0
    @match_num = attr[:match_num] || 0
    @match_current = attr[:match_current] || 0
  end

  # basically to_network
  # int array the server sends to the client
  def to_a
    Packer.pack_int(@game_flags) +
      Packer.pack_int(@score_limit) +
      Packer.pack_int(@time_limit) +
      Packer.pack_int(@match_num) +
      Packer.pack_int(@match_current)
  end
end
