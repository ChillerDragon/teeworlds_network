# frozen_string_literal: true

require_relative 'map'
require_relative 'server_info'
require_relative 'game_info'

class GameServer
  attr_accessor :pred_game_tick, :ack_game_tick, :map

  def initialize(server)
    @server = server
    @ack_game_tick = -1
    @pred_game_tick = 0
    @map = Map.new(
      name: 'dm1',
      crc: '98a0a4c50c', # decimal 64548818
      size: 6793,
      sha256: '491af17a510214506270904f147a4c30ae0a85b91bb854395bef8c397fc078c3'
    )
  end

  def on_info(chunk, packet)
    u = Unpacker.new(chunk.data[1..])
    net_version = u.get_string
    password = u.get_string
    client_version = u.get_int
    puts "vers=#{net_version} vers=#{client_version} pass=#{password}"

    # TODO: check version and password

    @server.send_map(packet.client)
  end

  def on_ready(_chunk, packet)
    # vanilla server sends 3 chunks here usually
    #  - motd
    #  - server settings
    #  - ready
    #
    # We only send ready for now
    @server.send_ready(packet.client)
  end

  def on_startinfo(_chunk, packet)
    # vanilla server sends 3 chunks here usually
    #  - vote clear options
    #  - tune params
    #  - ready to enter
    #
    # We only send ready to enter for now
    @server.send_ready_to_enter(packet.client)
  end

  def on_enter_game(_chunk, packet)
    # vanilla server responds to enter game with two packets
    # first:
    #  - server info
    # second:
    #  - game info
    #  - client info
    #  - snap single
    @server.send_server_info(packet.client, ServerInfo.new.to_a)
    @server.send_game_info(packet.client, GameInfo.new.to_a)
  end

  def on_rcon_cmd(chunk, packet)
    u = Unpacker.new(chunk.data[1..])
    cmd = u.get_string
    puts "got rcon_cmd=#{cmd}"
  end

  def on_input(chunk, packet)
    # vanilla server responds to input with 2 chunks
    #  - input_timing
    #  - snap (empty)

    # we do nothing for now
    # TODO: do something
  end

  def disconnect_client(client, reason = nil)
    @server.send_ctrl_close(client, reason)
  end

  def on_tick
    now = Time.now
    timeout_ids = []
    @server.clients.each do |id, client|
      diff = now - client.last_recv_time
      timeout_ids.push(id) if diff > 10
    end

    timeout_ids.each do |id|
      disconnect_client(@server.clients[id], 'Timeout')
      @server.clients.delete(id)
    end
  end
end
