require_relative '../lib/packet'

describe 'Packet', :packet do
  context 'Set flag bits' do
    it 'Should set the control flag bit' do
      expect(PacketFlags.new(control: true).bits).to eq('0001')
    end
  end
end
