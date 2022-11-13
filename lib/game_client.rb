# frozen_string_literal: true

require_relative 'models/player'
require_relative 'models/chat_message'
require_relative 'packer'

class Context
  attr_reader :old_data, :client
  attr_accessor :data

  def initialize(client, keys = {})
    @client = client
    @cancle = false
    @old_data = keys
    @data = keys
  end

  def verify
    @data.each do |key, _value|
      next if @old_data.key? key

      raise "Error: invalid data key '#{key}'\n       valid keys: #{@old_data.keys}"
    end
  end

  def cancled?
    @cancle
  end

  def cancle
    @cancle = true
  end
end

class GameClient
  attr_accessor :players, :pred_game_tick, :ack_game_tick

  def initialize(client)
    @client = client
    @players = {}
    @ack_game_tick = -1
    @pred_game_tick = 0
  end

  def on_client_info(chunk)
    # puts "Got playerinfo flags: #{chunk.flags}"
    u = Unpacker.new(chunk.data[1..])
    player = Player.new(
      id: u.get_int,
      local: u.get_int,
      team: u.get_int,
      name: u.get_string,
      clan: u.get_string,
      country: u.get_int
    )
    # skinparts and the silent flag
    # are currently ignored

    context = Context.new(
      @client,
      player:,
      chunk:
    )
    if @client.hooks[:client_info]
      @client.hooks[:client_info].call(context)
      context.verify
      return if context.cancled?
    end

    player = context.data[:player]
    @players[player.id] = player
  end

  def on_client_drop(chunk)
    u = Unpacker.new(chunk.data[1..])
    client_id = u.get_int
    reason = u.get_string
    silent = u.get_int

    context = Context.new(
      @cliemt,
      player: @players[client_id],
      chunk:,
      client_id:,
      reason: reason == '' ? nil : reason,
      silent: silent != 0
    )
    if @client.hooks[:client_drop]
      @client.hooks[:client_drop].call(context)
      context.verify
      return if context.cancled?
    end

    @players.delete(context.data[:client_id])
  end

  def on_ready_to_enter(_chunk)
    @client.send_enter_game
  end

  def on_connected
    context = Context.new(@client)
    if @client.hooks[:connected]
      @client.hooks[:connected].call(context)
      context.verify
      return if context.cancled?
    end
    @client.send_msg_startinfo
  end

  def on_disconnect
    @client.hooks[:disconnect]&.call
  end

  def on_rcon_line(chunk)
    u = Unpacker.new(chunk.data[1..])
    context = Context.new(
      @client,
      line: u.get_string
    )
    @client.hooks[:rcon_line]&.call(context)
  end

  def on_snapshot(chunk)
    u = Unpacker.new(chunk.data)
    u.get_int
    # msg = u.get_int
    # msg >>= 1

    # num_parts = 1
    # part = 0
    game_tick = u.get_int
    # delta_tick = u.get_int
    # part_size = 0
    # crc = 0
    # complete_size = 0
    # data = nil

    # TODO: state check

    # if msg == NETMSG_SNAP
    #   num_parts = u.get_int
    #   part = u.get_int
    # end

    # unless msg == NETMSG_SNAPEMPTY
    #   crc = u.get_int
    #   part_size = u.get_int
    # end

    # TODO: add get_raw(size)
    # data = u.get_raw

    # ack every snapshot no matter how broken
    @ack_game_tick = game_tick
    return unless (@pred_game_tick - @ack_game_tick).abs > 10

    @pred_game_tick = @ack_game_tick + 1
  end

  def on_emoticon(chunk); end

  def on_map_change(chunk)
    context = Context.new(@client, chunk:)
    if @client.hooks[:map_change]
      @client.hooks[:map_change].call(context)
      context.verify
      return if context.cancled?
    end
    # ignore mapdownload at all times
    # and claim to have the map
    @client.send_msg_ready
  end

  def on_chat(chunk)
    u = Unpacker.new(chunk.data[1..])
    data = {
      mode: u.get_int,
      client_id: u.get_int,
      target_id: u.get_int,
      message: u.get_string
    }
    data[:author] = @players[data[:client_id]]
    msg = ChatMesage.new(data)

    @client.hooks[:chat]&.call(msg)
  end
end
