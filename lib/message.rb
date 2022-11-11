# frozen_string_literal: true

##
# Turns int into network byte
#
# Takes a NETMSGTYPE_CL_* integer
# and returns a byte that can be send over
# the network
def pack_msg_id(msg_id, options = { system: false })
  (msg_id << 1) | (options[:system] ? 1 : 0)
end
