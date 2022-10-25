#!/usr/bin/env ruby

require 'socket'

# randomize this
MY_TOKEN = [0x73, 0x34, 0xB4, 0xA0]

MSG_TOKEN = [0x04, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0x05] + MY_TOKEN + Array.new(512, 0x00)
MSG_INFO = [0x40, 0x19, 0x01, 0x03, 0x30, 0x2E, 0x37, 0x20, 0x38, 0x30, 0x32, 0x66, # @...0.7 802f
            0x31, 0x62, 0x65, 0x36, 0x30, 0x61, 0x30, 0x35, 0x36, 0x36, 0x35, 0x66, # 1be60a05665f
            0x00, 0x00, 0x85, 0x1C]
MSG_STARTINFO = [0x41, 0x19, 0x03, 0x36, 0x6E, 0x61, 0x6D, 0x65 , 0x6C, 0x65, 0x73, 0x73, # A..6nameless
                  0x20, 0x6D, 0x65, 0x00, 0x00, 0x40, 0x67, 0x72 , 0x65, 0x65, 0x6E, 0x73, # me..@greens
                  0x77, 0x61, 0x72, 0x64, 0x00, 0x64, 0x75, 0x6F , 0x64, 0x6F, 0x6E, 0x6E, # ward.duodonn
                  0x79, 0x00, 0x00, 0x73, 0x74, 0x61, 0x6E, 0x64 , 0x61, 0x72, 0x64, 0x00, # y..standard
                  0x73, 0x74, 0x61, 0x6E, 0x64, 0x61, 0x72, 0x64 , 0x00, 0x73, 0x74, 0x61, # standard.sta
                  0x6E, 0x64, 0x61, 0x72, 0x64, 0x00, 0x01, 0x01 , 0x00, 0x00, 0x00, 0x00, # ndard.......
                  0x80, 0xFC, 0xAF, 0x05, 0xEB, 0x83, 0xD0, 0x0A , 0x80, 0xFE, 0x07, 0x80, # ............
                  0xFE, 0x07, 0x80, 0xFE, 0x07, 0x80, 0xFE, 0x07]


NET_CTRLMSG_CONNECT = 0x01
NET_CTRLMSG_ACCEPT = 0x02
NET_CTRLMSG_CLOSE = 0x04
NET_CTRLMSG_TOKEN = 0x05

NET_CONNSTATE_OFFLINE = 0
NET_CONNSTATE_TOKEN = 1
NET_CONNSTATE_CONNECT = 2
NET_CONNSTATE_PENDING = 3
NET_CONNSTATE_ONLINE = 4
NET_CONNSTATE_ERROR = 5

NET_MAX_PACKETSIZE = 1400

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
  end

  # turn byte array into hex string
  def str_hex(data)
    data.unpack("H*").first.scan(/../).join(' ').upcase
  end

  # turn hex string to byte array
  def str_bytes(str)
    str.scan(/../).map{ |b| b.to_i(16) }
  end

  def bytes_to_str(data)
    data.unpack("H*").join('')
  end

  def get_byte(data, start = 0, num = 1)
    data[start...(start+num)].unpack("H*").join('').upcase
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

  def tick
    # puts "tick"
    begin
      pck = @s.recvfrom_nonblock(1400)
    rescue
      pck = nil
    end
    return unless pck

    data = pck.first
    # puts "data: #{str_hex(data)}"

    # bit operate the first header byte
    # instead of assuming size 7
    header_size = 7

    msg = get_byte(data, header_size)

    # check flags properly instead
    if get_byte(data, 0) == '00'
      # parse msg with bit flips instead
      on_message(msg, data[(header_size + 1)..])
    elsif get_byte(data, 0) == '10' # size 7 flags compression
      # puts "we f*cked this compressed"
      if @server_info.nil?
        send_msg_startinfo
      else # assume snap reply with input to keep alive
        send_input
      end
    else
      on_ctrl_message(msg.to_i(16), data[(header_size + 1)..])
    end
  end

  def disconnect
    @s.close
  end
end

client = TwClient.new

client.connect(ARGV[0] || "localhost", ARGV[1] ? ARGV[1].to_i : 8303)

