# frozen_string_literal: true

AVAILABLE_COLORS = %i[
  red green yellow pink magenta blue cyan white
  bg_red bg_green bg_yellow bg_pink bg_magenta bg_blue bg_cyan bg_white
].freeze

# String color
class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  # foreground
  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def blue
    colorize(34)
  end

  def pink
    colorize(35)
  end

  # keklul pink alias
  def magenta
    colorize(35)
  end

  def cyan
    colorize(36)
  end

  def white
    colorize(37)
  end

  # background
  def bg_red
    colorize(41)
  end

  def bg_green
    colorize(42)
  end

  def bg_yellow
    colorize(43)
  end

  def bg_blue
    colorize(44)
  end

  def bg_pink
    colorize(45)
  end

  # keklul pink alias
  def bg_magenta
    colorize(45)
  end

  def bg_cyan
    colorize(46)
  end

  def bg_white
    colorize(47)
  end
end
