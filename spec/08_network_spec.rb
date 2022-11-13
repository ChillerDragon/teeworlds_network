# frozen_string_literal: true

require_relative '../lib/network'

describe 'Network', :network do
  context 'Should not crash' do
    it 'Should set SERVER_TICK_SPEED' do
      expect(SERVER_TICK_SPEED).to eq(50)
    end
  end
end
