# frozen_string_literal: true

class Player
  attr_accessor :id, :local, :team, :name, :clan, :country, :skin_parts, :skin_custom_colors, :skin_colors, :score

  def initialize(data = {})
    @id = data[:id] || -1
    @local = data[:local] || 0
    @team = data[:team] || 0
    @name = data[:name] || '(connecting..)'
    @clan = data[:clan] || ''
    @country = data[:country] || -1
    @skin_parts = data[:skin_parts] || Array.new(6, 'standard')
    @skin_custom_colors = data[:skin_custom_colors] || Array.new(6, 0)
    @skin_colors = data[:skin_colors] || Array.new(6, 0)

    @score = data[:score] || 0
  end
end
