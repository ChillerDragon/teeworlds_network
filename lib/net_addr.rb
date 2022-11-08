# frozen_string_literal: true

class NetAddr
  attr_accessor :ip, :port

  def initialize(ip, port)
    @ip = ip
    @port = port
  end
end
