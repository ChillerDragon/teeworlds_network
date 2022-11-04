require_relative 'player'
require_relative 'packer'
require_relative 'chat_message'

class GameClient
  attr_accessor :players

  def initialize(client)
    @client = client
    @players = {}
  end

  def on_player_join(chunk)
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

    @players[player.id] = player
    puts "'#{player.name}' joined the game"
  end

  def on_chat(chunk)
    #   06     01     00     40      41  00
    #   msg    mode   cl_id  trgt    A   nullbyte?
    #          all           -1
    # mode = chunk.data[1]
    # client_id = chunk.data[2]
    # target = chunk.data[3]
    # msg = chunk.data[4..]

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

