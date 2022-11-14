# frozen_string_literal: true

class Context
  attr_reader :old_data, :client
  attr_accessor :data

  def initialize(client, keys = {})
    @client = client
    @cancle = false
    @old_data = keys
    @data = keys
  end

  def verify
    @data.each do |key, _value|
      next if @old_data.key? key

      raise "Error: invalid data key '#{key}'\n       valid keys: #{@old_data.keys}"
    end
  end

  def cancled?
    @cancle
  end

  def cancle
    @cancle = true
  end
end
