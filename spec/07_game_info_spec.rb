# frozen_string_literal: true

require_relative '../lib/models/game_info'

describe 'GameInfo', :game_info do
  context 'Pack to network' do
    it 'Should match expected array' do
      expect(GameInfo.new.to_a).to eq([0, 0, 0, 0, 0])
    end
  end
end
