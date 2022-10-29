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

def todo_make_this_a_rspec_test()
  p (1..10).to_a.groups_of(2) == [[1, 2], [3, 4], [5, 6], [7, 8], [9, 10]]
  p (1..10).to_a.groups_of(20) == [[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]]
end

