# frozen_string_literal: true

##
# Only used for chunks where the sequence number does not match the expected value
# to decide wether to drop known chunks silently or request resend if something got lost
#
# true - if the sequence number is already known and the chunk should be dropped
# false - if the sequence number is off and we need to request a resend of lost chunks
#
# @return [Boolean]
def seq_in_backroom?(seq, ack)
  bottom = ack - (NET_MAX_SEQUENCE / 2)
  if bottom.negative?
    return true if seq <= ack
    return true if seq >= (bottom + NET_MAX_SEQUENCE)
  elsif seq <= ack && seq >= bottom
    return true
  end
  false
end
