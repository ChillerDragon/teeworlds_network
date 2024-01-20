# frozen_string_literal: true

class Context
  attr_reader :old_data
  attr_accessor :data, :message

  def initialize(message, keys = {})
    @message = message # the obj holding the parsed chunk
    @cancel = false
    @old_data = keys
    @data = keys
  end

  def verify
    @data.each_key do |key|
      next if @old_data.key? key

      raise "Error: invalid data key '#{key}'\n       valid keys: #{@old_data.keys}"
    end
  end

  def canceld?
    @cancel
  end

  def cancel
    @cancel = true
  end
end
