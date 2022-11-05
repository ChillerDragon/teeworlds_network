# frozen_string_literal: true

class ChatMesage
  attr_reader :mode, :client_id, :target_id, :message, :author

  def initialize(data = {})
    # @mode
    # Type: Integer
    @mode = data[:mode]

    # @client_id
    # Type: Integer
    @client_id = data[:client_id]

    # @target_id
    # Type: Integer
    @target_id = data[:target_id]

    # @message
    # Type: String
    @message = data[:message]

    # @author
    # Type: Player see player.rb
    @author = data[:author]
  end

  def to_s
    "#{@author.name}: #{@message}"
  end
end
