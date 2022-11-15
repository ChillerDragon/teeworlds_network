# frozen_string_literal: true

class Context
  attr_reader :old_data
  attr_accessor :data, :todo_rename_this

  def initialize(todo_rename_this, keys = {})
    @todo_rename_this = todo_rename_this # the obj holding the parsed chunk
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
