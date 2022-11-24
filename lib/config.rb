# frozen_string_literal: true

class Config
  def initialize(options = {})
    filepath = options[:file] || 'autoexec.cfg'
    init_configs
    load_cfg(filepath)
  end

  def init_configs
    @configs = {
      password: { help: 'Password to the server', default: '' }
    }
    @commands = {
      echo: { help: 'Echo the text', callback: proc { |arg| puts arg } },
      quit: { help: 'Quit', callback: proc { |_| exit } }
    }
    @configs.each do |cfg, data|
      self.class.send(:attr_accessor, cfg)
      instance_variable_set("@#{cfg}", data[:default])
    end
  end

  def load_cfg(file)
    return unless File.exist?(file)

    File.readlines(file).each_with_index do |line, line_num|
      line.strip!
      next if line.start_with? '#'
      next if line.empty?

      words = line.split
      cmd = words.shift.to_sym
      arg = words.join(' ')
      if @configs[cmd]
        instance_variable_set("@#{cmd}", arg)
      elsif @commands[cmd]
        @commands[cmd][:callback].call(arg)
      else
        puts "Warning: unsupported config '#{cmd}' #{file}:#{line_num}"
      end
    end
  end
end
