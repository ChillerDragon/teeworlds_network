# frozen_string_literal: true

class ServerSettings
  def initialize(attr = {})
    @kick_vote = attr[:kick_vote] || 0
    @kick_min = attr[:kick_min] || 0
    @spec_vote = attr[:spec_vote] || 0
    @team_lock = attr[:team_lock] || 0
    @team_balance = attr[:team_balance] || 0
    @player_slots = attr[:player_slots] || 16
  end

  # basically to_network
  # int array the server sends to the client
  def to_a
    Packer.pack_int(@kick_vote) +
      Packer.pack_int(@kick_min) +
      Packer.pack_int(@spec_vote) +
      Packer.pack_int(@team_lock) +
      Packer.pack_int(@team_balance) +
      Packer.pack_int(@player_slots)
  end
end
