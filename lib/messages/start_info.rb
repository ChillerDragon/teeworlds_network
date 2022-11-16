# frozen_string_literal: true

require_relative '../packer'

# TODO: use this on the client side instead of the other hash

##
# StartInfo
#
# Client -> Server
class StartInfo
  attr_accessor :name, :clan, :country, :body, :marking, :decoration, :hands, :feet, :eyes,
                :custom_color_body, :custom_color_marking, :custom_color_decoration,
                :custom_color_hands, :custom_color_feet, :custom_color_eyes,
                :color_body, :color_marking, :color_decoration, :color_hands, :color_feet, :color_eyes

  def initialize(hash_or_raw)
    if hash_or_raw.instance_of?(Hash)
      init_hash(hash_or_raw)
    else
      init_raw(hash_or_raw)
    end
  end

  def init_raw(data)
    u = Unpacker.new(data)
    @name = u.get_string
    @clan = u.get_string
    @country = u.get_int
    @body = u.get_string
    @marking = u.get_string
    @decoration = u.get_string
    @hands = u.get_string
    @feet = u.get_string
    @eyes = u.get_string
    @custom_color_body = u.get_int
    @custom_color_marking = u.get_int
    @custom_color_decoration = u.get_int
    @custom_color_hands = u.get_int
    @custom_color_feet = u.get_int
    @custom_color_eyes = u.get_int
    @color_body = u.get_int
    @color_marking = u.get_int
    @color_decoration = u.get_int
    @color_hands = u.get_int
    @color_feet = u.get_int
    @color_eyes = u.get_int
  end

  def init_hash(attr)
    @name = attr[:name] || 'ruby gamer'
    @clan = attr[:clan] || ''
    @country = attr[:country] || -1
    @body = attr[:body] || 'spiky'
    @marking = attr[:marking] || 'duodonny'
    @decoration = attr[:decoration] || ''
    @hands = attr[:hands] || 'standard'
    @feet = attr[:feet] || 'standard'
    @eyes = attr[:eyes] || 'standard'
    @custom_color_body = attr[:custom_color_body] || 0
    @custom_color_marking = attr[:custom_color_marking] || 0
    @custom_color_decoration = attr[:custom_color_decoration] || 0
    @custom_color_hands = attr[:custom_color_hands] || 0
    @custom_color_feet = attr[:custom_color_feet] || 0
    @custom_color_eyes = attr[:custom_color_eyes] || 0
    @color_body = attr[:color_body] || 0
    @color_marking = attr[:color_marking] || 0
    @color_decoration = attr[:color_decoration] || 0
    @color_hands = attr[:color_hands] || 0
    @color_feet = attr[:color_feet] || 0
    @color_eyes = attr[:color_eyes] || 0
  end

  def to_h
    {
      name: @name,
      clan: @clan,
      country: @country,
      body: @body,
      marking: @marking,
      decoration: @decoration,
      hands: @hands,
      feet: @feet,
      eyes: @eyes,
      custom_color_body: @custom_color_body,
      custom_color_marking: @custom_color_marking,
      custom_color_decoration: @custom_color_decoration,
      custom_color_hands: @custom_color_hands,
      custom_color_feet: @custom_color_feet,
      custom_color_eyes: @custom_color_eyes,
      color_body: @color_body,
      color_marking: @color_marking,
      color_decoration: @color_decoration,
      color_hands: @color_hands,
      color_feet: @color_feet,
      color_eyes: @color_eyes
    }
  end

  # basically to_network
  # int array the client sends to the server
  def to_a
    Packer.pack_str(@name) +
      Packer.pack_str(@clan) +
      Packer.pack_int(@country) +
      Packer.pack_str(@body) +
      Packer.pack_str(@marking) +
      Packer.pack_str(@decoration) +
      Packer.pack_str(@hands) +
      Packer.pack_str(@feet) +
      Packer.pack_str(@eyes) +
      Packer.pack_int(@custom_color_body) +
      Packer.pack_int(@custom_color_marking) +
      Packer.pack_int(@custom_color_decoration) +
      Packer.pack_int(@custom_color_hands) +
      Packer.pack_int(@custom_color_feet) +
      Packer.pack_int(@custom_color_eyes) +
      Packer.pack_int(@color_body) +
      Packer.pack_int(@color_marking) +
      Packer.pack_int(@color_decoration) +
      Packer.pack_int(@color_hands) +
      Packer.pack_int(@color_feet) +
      Packer.pack_int(@color_eyes)
  end

  def to_s
    to_h
  end
end
