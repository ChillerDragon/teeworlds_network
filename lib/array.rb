class Array
  def groups_of(max_size)
    return [] if max_size < 1

    groups = []
    group = []
    self.each do |item|
      group.push(item)

      if group.size >= max_size
        groups.push(group)
        group = []
      end
    end
    groups.push(group) unless group.size.zero?
    groups
  end
end

