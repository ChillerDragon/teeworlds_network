require_relative '../lib/array'

describe 'Array', :array do
  context 'Simple groups' do
    it 'Should do groups of two' do
      expect((1..10).to_a.groups_of(2)).to eq([[1, 2], [3, 4], [5, 6], [7, 8], [9, 10]])
    end
    it 'Should create one group if the input is less than the group size' do
      expect((1..10).to_a.groups_of(20)).to eq([[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]])
    end
  end
end

