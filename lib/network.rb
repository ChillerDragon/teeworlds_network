GAME_VERSION = "0.7.5"
GAME_NETVERSION_HASH_FORCED = "802f1be60a05665f"
GAME_NETVERSION = "0.7 " + GAME_NETVERSION_HASH_FORCED
CLIENT_VERSION = 0x0705

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

