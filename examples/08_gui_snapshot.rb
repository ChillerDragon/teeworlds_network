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
  end

  def update
    @client.on_snapshot do |_, snap|
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
    return if @tees.empty?

    offset = center_around_tee(@tees.first.last)
    @tees.each do |_id, tee|
      draw_rect(
        tee.x + offset.x,
        tee.y + offset.y,
        tee.w,
        tee.h,
        Gosu::Color.argb(0xff_00ff00)
      )
    end
  end
end

Gui.new.show
