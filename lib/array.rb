# frozen_string_literal: true

# I JUST REALIZED I ALREADY USED .scan(/../)
# TO GET .groups_of(2)
# AND DUUUUH .scan() IS BASICALLY ALREADY
# .groups_of()
# TODO: get rid of it?!
# update: no
# .scan(/../) works on strings and groups_of works on arrays
# so it has its purpose
class Array
  def groups_of(max_size)
    return [] if max_size < 1

    groups = []
    group = []
    each do |item|
      group.push(item)

      if group.size >= max_size
        groups.push(group)
        group = []
      end
    end
    groups.push(group) unless group.empty?
    groups
  end
end
