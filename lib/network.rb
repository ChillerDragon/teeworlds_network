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

NETMSG_NULL = 0
NETMSG_INFO = 1
NETMSG_MAP_CHANGE = 2 # sent when client should switch map
NETMSG_MAP_DATA = 3   # map transfer, contains a chunk of the map file
NETMSG_SERVERINFO = 4
NETMSG_CON_READY = 5  # connection is ready, client should send start info
NETMSG_SNAP = 6       # normal snapshot, multiple parts
NETMSG_SNAPEMPTY = 7  # empty snapshot
NETMSG_SNAPSINGLE = 8 # ?
NETMSG_SNAPSMALL = 9
NETMSG_INPUTTIMING = 10   # reports how off the input was
NETMSG_RCON_AUTH_ON = 11  # rcon authentication enabled
NETMSG_RCON_AUTH_OFF = 12 # rcon authentication disabled
NETMSG_RCON_LINE = 13     # line that should be printed to the remote console
NETMSG_RCON_CMD_ADD = 14
NETMSG_RCON_CMD_REM = 15

# sent by client
NETMSG_READY = 18
NETMSG_ENTERGAME = 19
NETMSG_INPUT = 20 # contains the inputdata from the client
NETMSG_RCON_CMD = 21
NETMSG_RCON_AUTH = 22
NETMSG_REQUEST_MAP_DATA = 23

NETMSG_INVALID = 0
NETMSGTYPE_SV_MOTD = 1
NETMSGTYPE_SV_BROADCAST = 2
NETMSGTYPE_SV_CHAT = 3
NETMSGTYPE_SV_TEAM = 4
NETMSGTYPE_SV_KILLMSG = 5
NETMSGTYPE_SV_TUNEPARAMS = 6
NETMSGTYPE_SV_EXTRAPROJECTILE = 7
NETMSGTYPE_SV_READYTOENTER = 8
NETMSGTYPE_SV_WEAPONPICKUP = 19
NETMSGTYPE_SV_EMOTICON = 10
NETMSGTYPE_SV_VOTECLEAROPTIONS = 11
NETMSGTYPE_SV_VOTEOPTIONLISTADD = 12
NETMSGTYPE_SV_VOTEOPTIONADD = 13
NETMSGTYPE_SV_VOTEOPTIONREMOVE = 14
NETMSGTYPE_SV_VOTESET = 15
NETMSGTYPE_SV_VOTESTATUS = 16
NETMSGTYPE_SV_SERVERSETTINGS = 17
NETMSGTYPE_SV_CLIENTINFO = 18
NETMSGTYPE_SV_GAMEINFO = 19
NETMSGTYPE_SV_CLIENTDROP = 20
NETMSGTYPE_SV_GAMEMSG = 21
NETMSGTYPE_DE_CLIENTENTER = 22
NETMSGTYPE_DE_CLIENTLEAVE = 23
NETMSGTYPE_CL_SAY = 24
NETMSGTYPE_CL_SETTEAM = 25
NETMSGTYPE_CL_SETSPECTATORMODE = 26
NETMSGTYPE_CL_STARTINFO = 27
NETMSGTYPE_CL_KILL = 28
NETMSGTYPE_CL_READYCHANGE = 29
NETMSGTYPE_CL_EMOTICON = 30
NETMSGTYPE_CL_VOTE = 31
NETMSGTYPE_CL_CALLVOTE = 32
NETMSGTYPE_SV_SKINCHANGE = 33
NETMSGTYPE_CL_SKINCHANGE = 34
NETMSGTYPE_SV_RACEFINISH = 35
NETMSGTYPE_SV_CHECKPOINT = 36
NETMSGTYPE_SV_COMMANDINFO = 37
NETMSGTYPE_SV_COMMANDINFOREMOVE = 38
NETMSGTYPE_CL_COMMAND = 39
NUM_NETMSGTYPES = 40

NET_CTRLMSG_KEEPALIVE = 0
NET_CTRLMSG_CONNECT = 1
NET_CTRLMSG_ACCEPT = 2
NET_CTRLMSG_CLOSE = 4
NET_CTRLMSG_TOKEN = 5

NET_MAX_SEQUENCE = 1<<10

NET_CONNSTATE_OFFLINE = 0
NET_CONNSTATE_TOKEN = 1
NET_CONNSTATE_CONNECT = 2
NET_CONNSTATE_PENDING = 3
NET_CONNSTATE_ONLINE = 4
NET_CONNSTATE_ERROR = 5

NET_MAX_PACKETSIZE = 1400

CHAT_NONE = 0
CHAT_ALL = 1
CHAT_TEAM = 2
CHAT_WHISPER = 3
NUM_CHATS = 4

TARGET_SERVER = -1

PACKET_HEADER_SIZE = 7
CHUNK_HEADER_SIZE = 3

