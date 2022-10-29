#!/usr/bin/env ruby

require 'socket'

require_relative 'lib/string'
require_relative 'lib/array'
require_relative 'lib/bytes'
require_relative 'lib/network'
require_relative 'lib/packet'

class ServerInfo
  attr_reader :version, :name, :map, :gametype

  def initialize(infos)
    @version = infos[0]
    @name = infos[1]
    @map = infos[2]
    @gametype = infos[3]
  end

  def to_s
    "version=#{@version} gametype=#{gametype} map=#{map} name=#{name}"
  end
end

class TwClient
  attr_reader :state

  def initialize
    @client_token = MY_TOKEN.map { |b| b.to_s(16) }.join('')
    puts "client token #{@client_token}"
    @s = UDPSocket.new
    @state = NET_CONNSTATE_OFFLINE
    @ip = 'localhost'
    @port = 8303
    @packet_flags = {}
  end

  def send_msg(data)
    # size and flags
    header = [0x00, 0x00, 0x01] + str_bytes(@token)
    msg = header + data
    @s.send(msg.pack('C*'), 0, @ip, @port)
  end

  def send_msg_connect()
    header = [0x04, 0x00, 0x00] + str_bytes(@token)
    msg = header + [NET_CTRLMSG_CONNECT] + str_bytes(@client_token) + Array.new(501, 0x00)
    @s.send(msg.pack('C*'), 0, @ip, @port)
  end

  def send_ctrl_with_token()
    @state = NET_CONNSTATE_TOKEN
    @s.send(MSG_TOKEN.pack('C*'), 0, @ip, @port)
  end

  def send_info()
    send_msg(MSG_INFO)
  end

  def send_msg_startinfo()
    header = [0x00, 0x04, 0x01] + str_bytes(@token)
    msg = header + MSG_STARTINFO
    @s.send(msg.pack('C*'), 0, @ip, @port)
  end

  def send_msg_ready()
    header = [0x00, 0x01, 0x01] + str_bytes(@token)
    msg = header + [0x40, 0x01, 0x02, 0x25]
    @s.send(msg.pack('C*'), 0, @ip, @port)
  end

  def send_enter_game()
    header = [0x00, 0x07, 0x01] + str_bytes(@token)
    msg = header + [0x40, 0x01, 0x04, 0x27]
    @s.send(msg.pack('C*'), 0, @ip, @port)
  end

  def send_input
    header = [0x10, 0x0A, 01] + str_bytes(@token)
    random_compressed_input = [
      0x4D, 0xE9, 0x48, 0x13, 0xD0, 0x0B, 0x6B, 0xFC, 0xB7, 0x2B, 0x6E, 0x00, 0xBA
    ]
    # this wont work we need to ack the ticks
    # and then compress it
    # CMsgPacker Msg(NETMSG_INPUT, true);
    # Msg.AddInt(m_AckGameTick);
    # Msg.AddInt(m_PredTick);
    # Msg.AddInt(Size);
    msg = header + random_compressed_input
    @s.send(msg.pack('C*'), 0, @ip, @port)
  end

  def on_msg_token(data)
      @token = bytes_to_str(data)
      puts "Got token #{@token}"
      send_msg_connect()
  end

  def on_msg_accept
    puts "got accept. connection online"
    @state = NET_CONNSTATE_ONLINE
    send_info
  end

  def on_msg_close
    puts "got NET_CTRLMSG_CLOSE"
  end

  def get_strings(data)
    strings = []
    str = ""
    data.chars.each do |b|
      # use a bunch of control characters as delimiters
      # https://en.wikipedia.org/wiki/Control_character
      if (0x00..0x0F).to_a.include?(b.unpack('C*').first)
        strings.push(str) unless str.length.zero?
        str = ""
        next
      end

      str += b
    end
    strings
  end

  def on_msg_map_change(data)
    mapname = get_strings(data).first
    puts "map: #{mapname}"
    send_msg_ready()
  end

  def connect(ip, port)
    @ip = ip
    @port = port
    puts "connecting to #{@ip}:#{@port} .."
    # s.bind("127.0.0.1", 7878)
    @s.connect(ip, port)
    send_ctrl_with_token
    loop do
    # 10.times do
      tick
    end
  end

  def on_motd(data)
    puts "motd: #{get_strings(data)}"
  end

  # wat is dis?
  def on_what(what, data)
    case what
    when '32'
      # hex 32
      on_msg_map_change(data)
    when '01' # dont know what that is but client responds with enter game
      send_enter_game
    when '27' # DM server name and gametype as strings
      @server_info = ServerInfo.new(get_strings(data)[1..])
      puts @server_info
    when '28' # CTF server name and gametype as strings
      @server_info = ServerInfo.new(get_strings(data)[1..])
      puts @server_info
    when '06'
      # $nameless me@greenswardduodonnystandardstandardstandard
      puts get_strings(data)
    when '31'
      # 1ctf]
    when '12'
      # got this when connecting to blchill
      # 3xNPY&@!7usAy?B0{<94\BlmapChill1=L{:'m[Pnb̨Ϧ7https://maps.zillyhuhn.com/BlmapChill_313db8824c7bcc3aa22793dad56d5b50ad6eee629307df01cca896cfa603c137.map@8BlmapChill1=L{:'m[Pnb̨Ϧ7
      send_msg_ready
    when '13'
      # idk some garbage
    else
      puts "Unkown what #{what}"
      puts "hex: #{str_hex(data)}"
      puts "raw: #{data}"
      exit
    end
  end

  def on_playerinfo(data)
    puts "playerinfo: #{get_strings(data).join(', ')}"
  end

  # CClient::ProcessServerPacket
  def on_message(msg, data)
    what = get_byte(data)
    puts "msg=#{msg} what=#{what}"
    # data = data[1..]
    case msg
    when '40' then on_what(what, data)
    when 'C0' then on_what(what, data)
    when '52' then puts "got 0x52 is this keep alive idk? ignoring it"
    when 'C1' then on_playerinfo(data)
    when '41' then on_playerinfo(data)
    when '43' then on_motd(data)
    else
      puts "Unkown message #{msg}"
      puts "hex: #{str_hex(data)}"
      puts "raw: #{data}"
      exit (1)
    end
  end

  # CClient::ProcessConnlessPacket
  def on_ctrl_message(msg, data)
    case msg
    when NET_CTRLMSG_TOKEN then on_msg_token(data)
    when NET_CTRLMSG_ACCEPT then on_msg_accept
    when NET_CTRLMSG_CLOSE then on_msg_close
    else
        puts "Uknown control message #{msg}"
        exit(1)
    end
  end

  def process_server_packet(data)
    puts "server packet with payload:"
    puts str_hex(data)

    # todo: getting flags and size out of the chunk header is a must
    #       the server responds to the clients ready packet with a compressed payload
    #       the content are 3 chunks
    #         - game.sv_motd
    #         - game.sv_server_settings
    #         - sys.con_ready
    #
    #       The decompressed payload looks like this:
    #       40 02 02 02 00 40 07 03 22 01 00 01 00 01 08 40 01 04 0B
    #       < SV MOTD    > < SV SERVER SETTINGS        > < READY   >
    #       size=2         size=7                        size=1
    #       msg=motd       kickvote=true                 msg  =   0B
    #       payload=""     kickmin...                             v
    #                                                             5

    # msg = data[CHUNK_HEADER_SIZE].unpack("C*").first
    # msg >>= 1
    # puts "msg: #{msg} type: #{msg.class}"
    # case msg
    # when NETMSG_MAP_CHANGE
    #   send_msg_ready
    # else
    #   puts "Unsupported msg: #{msg}"
    #   exit(1)
    # end
  end

  def tick
    # puts "tick"
    begin
      pck = @s.recvfrom_nonblock(1400)
    rescue
      pck = nil
    end
    return unless pck

    data = pck.first

    packet = Packet.new(data)
    puts packet.to_s

    # process connless packets data
    if packet.flags_control
      msg = data[PACKET_HEADER_SIZE].unpack("C*").first
      on_ctrl_message(msg, data[(PACKET_HEADER_SIZE + 1)..])
    else # process non-connless packets
      process_server_packet(packet.payload)
    end

    # # check flags properly instead
    # if get_byte(data, 0) == '00'
    #   # parse msg with bit flips instead
    #   on_message(msg, data[(header_size + 1)..])
    # elsif get_byte(data, 0) == '10' # size 7 flags compression
    #   payload = data[header_size..]
    #   # puts "payload   compressed: " + str_hex(payload)
    #   payload = @huffman.decompress(payload.unpack("C*"))
    #   # puts "payload decompressed: " + str_hex(payload.pack("C*"))

    #   # debug this datatype
    #   # the byte 0x11 is being sent
    #   # the tw server somehow reads 8 as NETMSG_SNAPSINGLE
    #   # and ruby gets 17 here which is the decimal of 0x11
    #   msg = payload[2]
    #   puts "msg=#{msg} msgtype=#{msg.class} payloadtype=#{payload.class}"
    #   if @server_info.nil?
    #     send_msg_startinfo
    #   else # assume snap reply with input to keep alive
    #     send_input
    #   end
    # else
    #   on_ctrl_message(msg.to_i(16), data[(header_size + 1)..])
    # end
  end

  def disconnect
    @s.close
  end
end

client = TwClient.new

client.connect(ARGV[0] || "localhost", ARGV[1] ? ARGV[1].to_i : 8303)

