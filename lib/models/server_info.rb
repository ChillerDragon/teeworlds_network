# frozen_string_literal: true

require_relative '../network'
require_relative 'player'
require_relative '../packer'

class ServerInfo
  attr_accessor :version, :name, :hostname, :map, :gametype, :flags, :num_players, :max_players, :num_clients,
                :max_clients, :players

  def initialize
    # short tokenless version
    @version = GAME_VERSION # '0.7.5'
    @name = 'unnamed ruby server'
    @hostname = 'localhost'
    @map = 'dm1'
    @gametype = 'dm'
    @flags = 0
    @num_players = 1
    @max_players = MAX_PLAYERS
    @num_clients = 1
    @max_clients = MAX_CLIENTS

    # token only
    @players = [
      Player.new(
        id: 0,
        local: 0,
        team: 0,
        name: 'sample player',
        clan: '',
        country: -1
      )
    ]
  end

  def to_s
    "version=#{@version} gametype=#{gametype} map=#{map} name=#{name}"
  end

  # basically to_network
  # int array the server sends to the client
  def to_a
    data = []
    data = Packer.pack_str(@version) +
           Packer.pack_str(@name) +
           Packer.pack_str(@hostname) +
           Packer.pack_str(@map) +
           Packer.pack_str(@gametype) +
           Packer.pack_int(@flags) +
           Packer.pack_int(@num_players) +
           Packer.pack_int(@max_players) +
           Packer.pack_int(@num_clients) +
           Packer.pack_int(@max_clients)
    @players.each do |player|
      data += Packer.pack_str(player.name)
      data += Packer.pack_str(player.clan)
      data += Packer.pack_int(player.country)
      data += Packer.pack_int(player.score)
      data += Packer.pack_int(0) # TODO: bot and spec flag
    end
    data
  end
end
