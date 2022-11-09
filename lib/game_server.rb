# frozen_string_literal: true

class GameServer
  attr_accessor :pred_game_tick, :ack_game_tick

  def initialize(server)
    @server = server
    @ack_game_tick = -1
    @pred_game_tick = 0
  end

  def on_info(chunk)
    u = Unpacker.new(chunk.data[1..])
    net_version = u.get_string
    password = u.get_string
    client_version = u.get_int
    puts "vers=#{net_version} vers=#{client_version} pass=#{password}"

    # TODO: respond with map info
    #       here tho? Check tw code when to send map info
  end
end
