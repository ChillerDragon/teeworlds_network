require_relative 'player'
require_relative 'packer'
require_relative 'chat_message'

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
    @data.each do |key, value|
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
  attr_accessor :players

  def initialize(client)
    @client = client
    @players = {}
  end

  def on_client_info(chunk)
    # puts "Got playerinfo flags: #{chunk.flags}"
    u = Unpacker.new(chunk.data[1..])
    player = Player.new(
      id: u.get_int(),
      local: u.get_int(),
      team: u.get_int(),
      name: u.get_string(),
      clan: u.get_string(),
      country: u.get_int())
    # skinparts and the silent flag
    # are currently ignored

    context = Context.new(
      @client,
      player: player,
      chunk: chunk
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
    client_id = u.get_int()
    reason = u.get_string()
    silent = u.get_int()

    context = Context.new(
      @cliemt,
      player: @players[client_id],
      chunk: chunk,
      client_id: client_id,
      reason: reason == '' ? nil : reason,
      silent: silent
    )
    if @client.hooks[:client_drop]
      @client.hooks[:client_drop].call(context)
      context.verify
      return if context.cancled?
    end

    @players.delete(context.data[:client_id])
  end

  def on_ready_to_enter(chunk)
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

  def on_emoticon(chunk)
  end

  def on_map_change(chunk)
    context = Context.new(@client, chunk: chunk)
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
      mode: u.get_int(),
      client_id: u.get_int(),
      target_id: u.get_int(),
      message: u.get_string()
    }
    data[:author] = @players[data[:client_id]]
    msg = ChatMesage.new(data)

    if @client.hooks[:chat]
      @client.hooks[:chat].call(msg)
    end
  end
end

