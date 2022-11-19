#!/usr/bin/env ruby
# frozen_string_literal: true

require 'gosu'
require_relative '../lib/teeworlds_client'

class Entitiy
  attr_reader :x, :y

  def initialize(attr = {})
    @x = attr[:x]
    @y = attr[:y]
  end
end

class Tee < Entitiy
  attr_reader :w, :h

  def initialize(attr = {})
    @w = 32
    @h = 32
    super
  end
end

WINDOW_WIDTH = 800
WINDOW_HEIGHT = 500

class Gui < Gosu::Window
  def initialize
    super WINDOW_WIDTH, WINDOW_HEIGHT
    self.caption = 'ruby teeworlds client'
    @client = TeeworldsClient.new
    @client.connect('localhost', 8303, detach: true)
    @tees = {}
    @background_image = Gosu::Image.new(img('jungle.png'))
    @tee_image = Gosu::Image.new(img('default.png'))
  end

  def img(path)
    File.join(File.dirname(__FILE__), 'img/', path)
  end

  def update
    @client.on_snapshot do |_, snap|
      @tees = {}
      snap.items.each do |item|
        next unless item.instance_of?(NetObj::Character)

        player = item.to_h
        @tees[player[:id]] = Tee.new(player)
      end
    end
  end

  def center_around_tee(tee)
    wc = WINDOW_WIDTH / 2
    hc = WINDOW_HEIGHT / 2
    x = -tee.x + wc
    y = -tee.y + hc
    Entitiy.new(x:, y:)
  end

  def draw
    @background_image.draw(0, 0, 0)
    return if @tees.empty?

    own_tee = @tees[@client.local_client_id]
    own_tee = @tees.first.last if own_tee.nil?
    offset = center_around_tee(own_tee)
    @tees.each do |_id, tee|
      @tee_image.draw(tee.x + offset.x, tee.y + offset.y)
    end
  end
end

Gui.new.show
