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

  def set_start_info(start_info)
    raise "expected: StartInfo got: #{start_info.class}" unless start_info.instance_of?(StartInfo)

    start_info = start_info.to_h
    @name = start_info[:name]
    @clan = start_info[:clan]
    @country = start_info[:country]
    @skin_parts = [
      start_info[:body],
      start_info[:marking],
      start_info[:decoration],
      start_info[:hands],
      start_info[:feet],
      start_info[:eyes]
    ]
    @skin_custom_colors = [
      start_info[:custom_color_body],
      start_info[:custom_color_marking],
      start_info[:custom_color_decoration],
      start_info[:custom_color_hands],
      start_info[:custom_color_feet],
      start_info[:custom_color_eyes]
    ]
    @skin_colors = [
      start_info[:color_body],
      start_info[:color_marking],
      start_info[:color_decoration],
      start_info[:color_hands],
      start_info[:color_feet],
      start_info[:color_eyes]
    ]
  end
end
