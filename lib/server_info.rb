class ServerInfo
  attr_reader :version, :name, :map, :gametype

  def initialize(infos)
    @version = infos[0]
    @name = infos[1]
    @map = infos[2]
    @gametype = infos[3]
  end

  def to_s
    "version=#{@version} gametype=#{gametype} map=#{map} name=#{name}"
  end
end
