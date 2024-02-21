# frozen_string_literal: true

# require_relative '../lib/snapshot/builder.rb'
#
# describe 'SnapshotBuilder', :snapshot do
#   context 'finish' do
#     it 'Should create correct snap' do
#       builder = SnapshotBuilder.new
#       snap = builder.finish
#       expected_payload = [
#         0x00, 0x01, 0x00, 0x0a, # removed_items=0 num_item_deltas=1 _zero=0 type=10 NetObj::Character
#         0x00, 0x29, 0x00, 0x0d, # id=0 tick=41 x=0 y=13
#         0x00, 0xb3, 0x36, 0x00, # vel_x=0 vel_y=3507 angle=0
#         0x00, 0x40, 0x00, 0x00, # direction=0 jumped=-1 hooked_player=0 hook_state=0
#         0x00, 0x00, 0x00, 0x00, # hook_tick=0 hook_x=0 hook_y=0 hook_dx=0
#         0x00, 0x00, 0x00, 0x00, # hook_dy=0 health=0 armor=0 ammo_count=0
#         0x00, 0x00, 0x00, 0x00, # weapon=0 emote=0 attack_tick=0 triggered_events=0
#       ]
#       expect(snap.to_a).to eq(expected_payload)
#     end
#   end
# end

# >>> snap NETMSG_SNAPSINGLE (8)
# id=8 game_tick=1908 delta_tick=38
# num_parts=1 part=0 crc=16846 part_size=28
#
# header:
# 11 b4 1d 26      ...& int 17 >> 1 = 8 int 1908 int 38
# 8e 87 02 1c      .... int 16846 int 28
#
# payload:
# 00 01 00 0a      .... removed_items=0 num_item_deltas=1 _zero=0 type=10 NetObj::Character
# 00 29 00 0d      .).. id=0 tick=41 x=0 y=13
# 00 b3 36 00      ..6. vel_x=0 vel_y=3507 angle=0
# 00 40 00 00      .@.. direction=0 jumped=-1 hooked_player=0 hook_state=0
# 00 00 00 00      .... hook_tick=0 hook_x=0 hook_y=0 hook_dx=0
# 00 00 00 00      .... hook_dy=0 health=0 armor=0 ammo_count=0
# 00 00 00 00      .... weapon=0 emote=0 attack_tick=0 triggered_events=0
