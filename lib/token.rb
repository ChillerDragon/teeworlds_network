# frozen_string_literal: true

require_relative 'bytes'

class SecurityToken
  def self.err_msg(msg, token)
    hex = ''
    hex = "hex: #{str_hex(token)}\n" if token.instance_of?(String)
    "Invalid token! Token should be a human readable hex string!\n" \
      "  Good sample token: aabbccdd\n" \
      "  #{msg}\n" \
      "  token: #{token}:#{token.class}\n" \
      "  #{hex}"
  end

  def self.validate(token)
    raise err_msg("Expected type: String got: #{token.class}", token) unless token.instance_of?(String)
    raise err_msg("Expected size: 8 got: #{token.size}", token) unless token.size == 8
  end
end
