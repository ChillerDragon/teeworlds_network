# frozen_string_literal: true

require_relative '../lib/snapshot/builder'
require_relative '../lib/snapshot/items/character'
require_relative '../lib/snapshot/items/pickup'
require_relative '../lib/snapshot/items/flag'
require_relative '../lib/snapshot/items/game_data'
require_relative '../lib/snapshot/items/game_data_team'
require_relative '../lib/snapshot/items/game_data_flag'
require_relative '../lib/snapshot/items/player_info'

describe 'SnapshotBuilder', :snapshot do
  context '#finish should create snap payload' do
    it 'Should build a snap with one character' do
      builder = SnapshotBuilder.new
      char = NetObj::Character.new(
        tick: 41, x: 0, y: 13,
        vel_x: 0, vel_y: 3507, angle: 0,
        direction: 0, jumped: -1, hooked_player: 0, hook_state: 0,
        hook_tick: 0, hook_x: 0, hook_y: 0, hook_dx: 0,
        hook_dy: 0, health: 0, armor: 0, ammo_count: 0,
        weapon: 0, emote: 0, attack_tick: 0, triggered_events: 0
      )
      builder.new_item(0, char)
      snap = builder.finish
      expected_payload = [
        0x0a, # type=10 NetObj::Character
        0x00, 0x29, 0x00, 0x0d, # id=0 tick=41 x=0 y=13
        0x00, 0xb3, 0x36, 0x00, # vel_x=0 vel_y=3507 angle=0
        0x00, 0x40, 0x00, 0x00, # direction=0 jumped=-1 hooked_player=0 hook_state=0
        0x00, 0x00, 0x00, 0x00, # hook_tick=0 hook_x=0 hook_y=0 hook_dx=0
        0x00, 0x00, 0x00, 0x00, # hook_dy=0 health=0 armor=0 ammo_count=0
        0x00, 0x00, 0x00, 0x00 # weapon=0 emote=0 attack_tick=0 triggered_events=0
      ]
      expect(snap.to_a).to eq(expected_payload)
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
    end
    it 'Should build a snap with multiple items' do
      builder = SnapshotBuilder.new
      builder.new_item(0, NetObj::Pickup.new(
                            x: 1424, y: 272, type: 0
                          ))
      builder.new_item(1, NetObj::Pickup.new(
                            x: 1488, y: 272, type: 2
                          ))
      builder.new_item(2, NetObj::Pickup.new(
                            x: 1552, y: 272, type: 3
                          ))
      builder.new_item(3, NetObj::Pickup.new(
                            x: 1616, y: 272, type: 4
                          ))
      builder.new_item(7, NetObj::Pickup.new(
                            x: 1392, y: 272, type: 1
                          ))
      builder.new_item(0, NetObj::Flag.new(
                            x: 1200, y: 304, team: 0
                          ))
      builder.new_item(1, NetObj::Flag.new(
                            x: 1296, y: 304, team: 1
                          ))
      builder.new_item(0, NetObj::GameData.new(
                            game_start_tick: 1286,
                            game_state_flags: 0, game_state_end_tick: 0
                          ))
      builder.new_item(0, NetObj::GameDataTeam.new(
                            teamscore_red: 0, teamscore_blue: 0
                          ))
      builder.new_item(0, NetObj::GameDataFlag.new(
                            flag_carrier_red: -2, flag_carrier_blue: -2,
                            flag_drop_tick_red: 0, flag_drop_tick_blue: 0
                          ))
      builder.new_item(0, NetObj::Character.new(
                            tick: 1314, x: 784, y: 306,
                            vel_x: 0, vel_y: 256, angle: -707,
                            direction: 0, jumped: 0, hooked_player: -1, hook_state: 0,
                            hook_tick: 0, hook_x: 784, hook_y: 305, hook_dx: 0,
                            hook_dy: 0, health: 0, armor: 0, ammo_count: 0,
                            weapon: 1, emote: 0, attack_tick: 0, triggered_events: 0
                          ))
      builder.new_item(1, NetObj::Character.new(
                            tick: 1313, x: 848, y: 305,
                            vel_x: 0, vel_y: 128, angle: 0,
                            direction: 0, jumped: 0, hooked_player: -1, hook_state: 0,
                            hook_tick: 0, hook_x: 848, hook_y: 304, hook_dx: 0,
                            hook_dy: 0, health: 10, armor: 0, ammo_count: 10,
                            weapon: 1, emote: 0, attack_tick: 0, triggered_events: 0
                          ))
      builder.new_item(0, NetObj::PlayerInfo.new(
                            player_flags: 8, score: 0, latency: 0
                          ))
      builder.new_item(1, NetObj::PlayerInfo.new(
                            player_flags: 8, score: 0, latency: 0
                          ))
      snap = builder.finish
      expected_payload = [
        0x04, # type=4 NetObj::Pickup
        0x00, 0x90, 0x16, 0x90, # id=0 x=1424 y=272
        0x04, 0x00, 0x04, 0x01, # y=272 type=0 id=1 type=4 NetObj::Pickup
        0x90, 0x17, 0x90, 0x04, # x=1488 y=272
        0x02, 0x04, 0x02, 0x90, # type=2 id=2 x=1552 type=4 NetObj::Pickup
        0x18, 0x90, 0x04, 0x03, # x=1552 y=272 type=3
        0x04, 0x03, 0x90, 0x19, # id=3 x=1616 type=4 NetObj::Pickup
        0x90, 0x04, 0x04, 0x04, # y=272 type=4 type=4 NetObj::Pickup
        0x07, 0xb0, 0x15, 0x90, # id=7 x=1392 y=272
        0x04, 0x01, 0x05, 0x00, # y=272 type=1 id=0 type=5 NetObj::Flag
        0xb0, 0x12, 0xb0, 0x04, # x=1200 y=304
        0x00, 0x05, 0x01, 0x90, # team=0 id=1 x=1296 type=5 NetObj::Flag
        0x14, 0xb0, 0x04, 0x01, # x=1296 y=304 team=1
        0x06, 0x00, 0x86, 0x14, # id=0 game_start_tick=1286 type=6 NetObj::GameData
        0x00, 0x00, 0x07, 0x00, # game_state_flags=0 game_state_end_tick=0 id=0 type=7 NetObj::GameDataTeam
        0x00, 0x00, 0x08, 0x00, # teamscore_red=0 teamscore_blue=0 id=0 type=8 NetObj::GameDataFlag
        0x41, 0x41, 0x00, 0x00, # flag_carrier_red=-2 flag_carrier_blue=-2 flag_drop_tick_red=0 flag_drop_tick_blue=0
        0x0a, 0x00, 0xa2, 0x14, # id=0 tick=1314 type=10 NetObj::Character
        0x90, 0x0c, 0xb2, 0x04, # x=784 y=306
        0x00, 0x80, 0x04, 0xc2, # vel_x=0 vel_y=256 angle=-707
        0x0b, 0x00, 0x00, 0x40, # angle=-707 direction=0 jumped=0 hooked_player=-1
        0x00, 0x00, 0x90, 0x0c, # hook_state=0 hook_tick=0 hook_x=784
        0xb1, 0x04, 0x00, 0x00, # hook_y=305 hook_dx=0 hook_dy=0
        0x00, 0x00, 0x00, 0x01, # health=0 armor=0 ammo_count=0 weapon=1
        0x00, 0x00, 0x00, 0x0a, # emote=0 attack_tick=0 triggered_events=0 type=10 NetObj::Character
        0x01, 0xa1, 0x14, 0x90, # id=1 tick=1313 x=848
        0x0d, 0xb1, 0x04, 0x00, # x=848 y=305 vel_x=0
        0x80, 0x02, 0x00, 0x00, # vel_y=128 angle=0 direction=0
        0x00, 0x40, 0x00, 0x00, # jumped=0 hooked_player=-1 hook_state=0 hook_tick=0
        0x90, 0x0d, 0xb0, 0x04, # hook_x=848 hook_y=304
        0x00, 0x00, 0x0a, 0x00, # hook_dx=0 hook_dy=0 health=10 armor=0
        0x0a, 0x01, 0x00, 0x00, # ammo_count=10 weapon=1 emote=0 attack_tick=0
        0x00, 0x0b, 0x00, 0x08, # triggered_events=0 id=0 player_flags=8 type=11 NetObj::PlayerInfo
        0x00, 0x00, 0x0b, 0x01, # score=0 latency=0 id=1 type=11 NetObj::PlayerInfo
        0x08, 0x00, 0x00 # player_flags=8 score=0 latency=0
      ]
      # snap.to_a.each_with_index do |s, i|
      #   p "[#{i}] got=#{s} want=#{expected_payload[i]}"
      #   expect(s).to eq(expected_payload[i])
      # end
      expect(snap.to_a).to eq(expected_payload)
      # >>> snap NETMSG_SNAPSINGLE (8)
      #   id=8 game_tick=1420 delta_tick=1421
      #   num_parts=1 part=0 crc=20053 part_size=139
      #
      #   header:
      #   11 8c 16 8d      .... int 17 >> 1 = 8 int 1420 int 1421
      #   16 95 b9 02      .... int 1421 int 20053
      #   8b 02            ..   int 139
      #
      #   payload:
      #   00 0e 00 04      .... removed_items=0 num_item_deltas=14 _zero=0 type=4 NetObj::Pickup
      #   00 90 16 90      .... id=0 x=1424 y=272
      #   04 00 04 01      .... y=272 type=0 id=1 type=4 NetObj::Pickup
      #   90 17 90 04      .... x=1488 y=272
      #   02 04 02 90      .... type=2 id=2 x=1552 type=4 NetObj::Pickup
      #   18 90 04 03      .... x=1552 y=272 type=3
      #   04 03 90 19      .... id=3 x=1616 type=4 NetObj::Pickup
      #   90 04 04 04      .... y=272 type=4 type=4 NetObj::Pickup
      #   07 b0 15 90      .... id=7 x=1392 y=272
      #   04 01 05 00      .... y=272 type=1 id=0 type=5 NetObj::Flag
      #   b0 12 b0 04      .... x=1200 y=304
      #   00 05 01 90      .... team=0 id=1 x=1296 type=5 NetObj::Flag
      #   14 b0 04 01      .... x=1296 y=304 team=1
      #   06 00 86 14      .... id=0 game_start_tick=1286 type=6 NetObj::GameData
      #   00 00 07 00      .... game_state_flags=0 game_state_end_tick=0 id=0 type=7 NetObj::GameDataTeam
      #   00 00 08 00      .... teamscore_red=0 teamscore_blue=0 id=0 type=8 NetObj::GameDataFlag
      #   41 41 00 00      AA.. flag_carrier_red=-2 flag_carrier_blue=-2 flag_drop_tick_red=0 flag_drop_tick_blue=0
      #   0a 00 a2 14      .... id=0 tick=1314 type=10 NetObj::Character
      #   90 0c b2 04      .... x=784 y=306
      #   00 80 04 c2      .... vel_x=0 vel_y=256 angle=-707
      #   0b 00 00 40      ...@ angle=-707 direction=0 jumped=0 hooked_player=-1
      #   00 00 90 0c      .... hook_state=0 hook_tick=0 hook_x=784
      #   b1 04 00 00      .... hook_y=305 hook_dx=0 hook_dy=0
      #   00 00 00 01      .... health=0 armor=0 ammo_count=0 weapon=1
      #   00 00 00 0a      .... emote=0 attack_tick=0 triggered_events=0 type=10 NetObj::Character
      #   01 a1 14 90      .... id=1 tick=1313 x=848
      #   0d b1 04 00      .... x=848 y=305 vel_x=0
      #   80 02 00 00      .... vel_y=128 angle=0 direction=0
      #   00 40 00 00      .@.. jumped=0 hooked_player=-1 hook_state=0 hook_tick=0
      #   90 0d b0 04      .... hook_x=848 hook_y=304
      #   00 00 0a 00      .... hook_dx=0 hook_dy=0 health=10 armor=0
      #   0a 01 00 00      .... ammo_count=10 weapon=1 emote=0 attack_tick=0
      #   00 0b 00 08      .... triggered_events=0 id=0 player_flags=8 type=11 NetObj::PlayerInfo
      #   00 00 0b 01      .... score=0 latency=0 id=1 type=11 NetObj::PlayerInfo
      #   08 00 00         ...  player_flags=8 score=0 latency=0
    end
  end
end
