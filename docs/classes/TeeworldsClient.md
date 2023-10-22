# TeeworldsClient

### <a name="initialize"></a> #initialize(options = {})

**Parameter: Hash**

Available keys:
- `:verbose [Boolean]` enables verbose output.
- `:verbose_snap [Boolean]` enables verbose output specific to the snap message.
- `:config [String]` path to autoexec.cfg file. As of right now only those commands are supported:
  + `password [yourpassword]` will be sent on connect
  + `echo [message]` prints a message
  + `quit` quits the client

**Example:**
```ruby
client = TeeworldsClient.new(verbose: true, config: "autoexec.cfg")

client.connect('localhost', 8303, detach: false)
```

### <a name="on_disconnect"></a> #on_disconnect(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is nil but there is a key `:reason` set in the context.data hash.

By default the following disconnect message is printed `puts "got disconnect. reason='#{context.data[:reason]}'"`
if you want to skip that behavior call the `context.cancel` method.

**Example:**
```ruby
client = TeeworldsClient.new

client.on_disconnect do |context|
  # remove default disconnect message
  context.cancel

  # implement custom disconnect message
  puts "got disconnect. reason='#{context.data[:reason]}'"
end

client.connect('localhost', 8303, detach: false)
```

### <a name="on_connected"></a> #on_connected(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is nil because there is no message payload.

By default the client will respond with the startinfo message.
This is crucial to establish a healthy connection to the server.
If you know what you are doing and do not want to send this message call `context.cancel`

**Example:**
```ruby
client = TeeworldsClient.new

client.on_connected do |context|
  puts "we got NETMSG_CON_READY from server"

  # skip default behavior
  context.cancel

  # send start info manually
  client.send_msg_start_info
end

client.connect('localhost', 8303, detach: false)
```

### <a name="on_rcon_line"></a> #on_rcon_line(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is a [RconLine](../classes/messages/RconLine.md)

By default the rcon line is printed to stdout in the following format `"[rcon] #{context.message.command}"`
if you want to skip that behavior call `context.cancel`

**Example:**
```ruby
client = TeeworldsClient.new

client.on_rcon_line do |context|
  # skip default print
  context.cancel

  # implement custom print
  puts "[rcon] #{context.message.command}"
end

client.connect('localhost', 8303, detach: false)
```

### <a name="on_auth_off"></a> #on_auth_off(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is nil because there is no message payload.

By default the client will print "rcon logged out" if you want to skip that behavior call `context.cancel`

**Example:**
```ruby
client = TeeworldsClient.new

client.on_auth_off do |context|
  # do not print default "rcon logged out" message
  context.cancel

  # implement custom message
  puts "rcon logged out"
end

client.connect('localhost', 8303, detach: false)
```

### <a name="on_auth_on"></a> #on_auth_on(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is nil because there is no message payload.

By default the client will print "rcon logged in" if you want to skip that behavior call `context.cancel`

**Example:**
```ruby
client = TeeworldsClient.new

client.on_auth_on do |context|
  # do not print default "rcon logged in" message
  context.cancel

  # implement custom message
  puts "rcon logged in"
end

client.connect('localhost', 8303, detach: false)
```

### <a name="on_input_timing"></a> #on_input_timing(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is a [InputTiming](../classes/messages/InputTiming.md)

**Example:**
```ruby
client = TeeworldsClient.new

client.on_input_timing do |context|
  puts "intended_tick: #{context.message.intended_tick}"
  puts "time_left: #{context.message.time_left}"
end

client.connect('localhost', 8303, detach: false)
```

### <a name="on_maplist_entry_rem"></a> #on_maplist_entry_rem(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is a [MaplistEntryRem](../classes/messages/MaplistEntryRem.md)

**Example:**
```ruby
client = TeeworldsClient.new

client.on_maplist_entry_rem do |context|
  # print all map names the server
  # sends to the client
  puts context.message.name
end

client.connect('localhost', 8303, detach: false)
```

### <a name="on_maplist_entry_add"></a> #on_maplist_entry_add(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is a [MaplistEntryAdd](../classes/messages/MaplistEntryAdd.md)

**Example:**
```ruby
client = TeeworldsClient.new

client.on_maplist_entry_add do |context|
  # print all map names the server
  # sends to the client
  puts context.message.name
end

client.connect('localhost', 8303, detach: false)
```

### <a name="on_rcon_cmd_rem"></a> #on_rcon_cmd_rem(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is a [RconCmdRem](../classes/messages/RconCmdRem.md)

**Example:**
```ruby
client = TeeworldsClient.new

client.on_rcon_cmd_rem do |context|
  puts "[rcon] command '#{context.message.name}' was removed"
end

client.connect('localhost', 8303, detach: false)
```

### <a name="on_rcon_cmd_add"></a> #on_rcon_cmd_add(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is a [RconCmdAdd](../classes/messages/RconCmdAdd.md)

**Example:**
```ruby
client = TeeworldsClient.new

client.on_rcon_cmd_add do |context|
  puts "[rcon] command '#{context.message.name}' was added"
end

client.connect('localhost', 8303, detach: false)
```

### <a name="on_snapshot"></a> #on_snapshot(&block)

**Parameter: block [Block |[context](../classes/Context.md), [Snapshot](../classes/Snapshot.md)|]**

context.message is nil but the block takes a second argument of type [Snapshot](../classes/Snapshot.md)

By default when a snapshot is received the `GameClient::ack_game_tick` and `GameClient::pred_game_tick`
variables are updated. Those are crucial for a healthy connection to the server. So only call `context.cancel`
if you know what you are doing

**Example:**
```ruby
client = TeeworldsClient.new

client.on_snapshot do |_, snapshot|
  snapshot.items.each do |item|
    next unless item.instance_of?(NetObj::Character)

    p item.to_h
    # => {:id=>0, :tick=>372118, :x=>1584, :y=>369, :vel_x=>0, :vel_y=>0, :angle=>0, :direction=>0, :jumped=>0, :hooked_player=>-1, :hook_state=>0, :hook_tick=>0, :hook_x=>1584, :hook_y=>369, :hook_dx=>0, :hook_dy=>0, :health=>0, :armor=>0, :ammo_count=>0, :weapon=>1, :emote=>0, :attack_tick=>0, :triggered_events=>0}

  end
end

client.connect('localhost', 8303, detach: false)
```

### <a name="on_client_info"></a> #on_client_info(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

**WARNING THIS API IS PLANNED TO CHANGE!**

context.message is nil but there is `context.data[:player]`

By default this prints the message `Our client id is <id>` if you want to skip that behavior
call `context.cancel`

**Example:**
```ruby
client = TeeworldsClient.new

client.on_client_info do |context|
  # print new player info
  p context.data[:player]
end

client.connect('localhost', 8303, detach: false)
```

### <a name="on_chat"></a> #on_chat(&block)

**Parameter: block [Block |[context](../classes/Context.md), [ChatMessage](../classes/ChatMessage.md)|]**

Takes a block that will be called when the client receives a chat message.
The block takes two parameters:
  [context](../classes/Context.md) - pretty much useless as of right now
  [ChatMessage](../classes/ChatMessage.md) - holds all the information of the chat message

**Example:**

```ruby
client = TeeworldsClient.new

client.on_chat do |context, msg|
  puts "[chat] #{msg}"
end

client.connect('localhost', 8303, detach: false)
```
### <a name="on_map_change"></a> #on_map_change(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

Takes a block that will be called when the client receives a map change packet.

**Example:**

```ruby
client = TeeworldsClient.new

client.on_map_change do |context|
  puts "Got new map!"

  # skip default behavior
  # in this case do not send the ready packet
  context.cancel
end

client.connect('localhost', 8303, detach: false)
```

### <a name="on_client_drop"></a> #on_client_drop(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

Takes a block that will be called when the client receives a client drop packet.

Context.data:

```ruby
[
  player: player_object,
  chunk: raw_packet_data,
  client_id: 0,
  reason: '',
  silent: false
]
```

**Example:**

```ruby
client.on_client_drop do |ctx|
  unless ctx.data[:silent]
    reason = ctx.data[:reason] ? " (#{ctx.data[:reason]})" : ''
    puts "'#{ctx.data[:player].name}' left the game#{reason}"
  end
end
```

### <a name="connect"></a> #connect(ip, port, options = {})

**Parameter: ip [String]**

**Parameter: port [Integer]**

**Parameter: options [Hash] (default: {detach: false})**

Connect to given server. The option ``:detach`` decides wether the connection should run in a background thread or not.
By default no thread will be spawned. And the ``connect()`` method blocks your main thread. Meaning no line below that will be run as long as the connection is up.

If you decide to provide the option ``detach: true`` it will spawn a thread and run the connection in there. Meaning it will jump to the next line after ``connect()`` is called. So it is your responsibility to keep the program running.
If the connection happens in the last line of your program it will just quit. So you have to keep it up using a loop for example.

**Example:**

```ruby
client = TeeworldsClient.new(verbose: true)

# this will spawn a background thread
client.connect('localhost', 8303, detach: true)
# this line will be run directly after the connection

# this line will be running as long as the connection is up
client.connect('localhost', 8303, detach: false)
# this line will only be run if the connection broke
```


### <a name="send_chat"></a> #send_chat(str)

**Parameter: str [String]**

Send a chat message. Takes the chat message as String.

**Example:**

```ruby
client = TeeworldsClient.new(verbose: true)

client.connect('localhost', 8303, detach: false)

client.send_chat('hello world!')
```

### <a name="rcon_authed"></a> #rcon_authed? -> Boolean

Returns true if the client is currently rcon authenticated.

**Example:**
```ruby
client = TeeworldsClient.new

client.connect('localhost', 8303, detach: true)

# give the client time to connect
sleep(4)

loop do
  if client.rcon_authed?
    puts "we are authenticated"
  else
    client.rcon_auth(password: "rcon")
  end
  sleep(1)
end
```
### <a name="send_ctrl_close"></a> #send_ctrl_close

**Parameter: TODO**

**Example:**
```ruby
client = TeeworldsClient.new

# TODO: generated documentation
client.send_ctrl_close

client.connect('localhost', 8303, detach: false)
```
### <a name="disconnect"></a> #disconnect

**Parameter: TODO**

**Example:**
```ruby
client = TeeworldsClient.new

# TODO: generated documentation
client.disconnect

client.connect('localhost', 8303, detach: false)
```
### <a name="set_startinfo"></a> #set_startinfo(info)

**Parameter: TODO**

**Example:**
```ruby
client = TeeworldsClient.new

# all keys are optional
# if not provided they will fall back to the default value
client.set_startinfo(
  name: 'ruby gamer',
  clan: '',
  country: -1,
  body: 'spiky',
  marking: 'duodonny',
  decoration: '',
  hands: 'standard',
  feet: 'standard',
  eyes: 'standard',
  custom_color_body: 0,
  custom_color_marking: 0,
  custom_color_decoration: 0,
  custom_color_hands: 0,
  custom_color_feet: 0,
  custom_color_eyes: 0,
  color_body: 0,
  color_marking: 0,
  color_decoration: 0,
  color_hands: 0,
  color_feet: 0,
  color_eyes: 0
)

client.connect('localhost', 8303, detach: false)
```
### <a name="send_msg"></a> #send_msg(data)

**Parameter: TODO**

**Example:**
```ruby
client = TeeworldsClient.new

# TODO: generated documentation
client.send_msg(data)

client.connect('localhost', 8303, detach: false)
```
### <a name="send_ctrl_keepalive"></a> #send_ctrl_keepalive

**Parameter: TODO**

**Example:**
```ruby
client = TeeworldsClient.new

# TODO: generated documentation
client.send_ctrl_keepalive

client.connect('localhost', 8303, detach: false)
```
### <a name="send_msg_connect"></a> #send_msg_connect

**Parameter: TODO**

**Example:**
```ruby
client = TeeworldsClient.new

# TODO: generated documentation
client.send_msg_connect

client.connect('localhost', 8303, detach: false)
```
### <a name="send_ctrl_with_token"></a> #send_ctrl_with_token

**Parameter: TODO**

**Example:**
```ruby
client = TeeworldsClient.new

# TODO: generated documentation
client.send_ctrl_with_token

client.connect('localhost', 8303, detach: false)
```
### <a name="send_info"></a> #send_info

**Parameter: TODO**

**Example:**
```ruby
client = TeeworldsClient.new

# TODO: generated documentation
client.send_info

client.connect('localhost', 8303, detach: false)
```
### <a name="rcon_auth"></a> #rcon_auth(name, password = nil)

**Parameter: TODO**

**Example:**
```ruby
client = TeeworldsClient.new

# TODO: generated documentation
client.rcon_auth(name, password = nil)

client.connect('localhost', 8303, detach: false)
```
### <a name="rcon"></a> #rcon(command)

**Parameter: TODO**

**Example:**
```ruby
client = TeeworldsClient.new

# TODO: generated documentation
client.rcon(command)

client.connect('localhost', 8303, detach: false)
```
### <a name="send_msg_start_info"></a> #send_msg_start_info

**Parameter: TODO**

**Example:**
```ruby
client = TeeworldsClient.new

# TODO: generated documentation
client.send_msg_start_info

client.connect('localhost', 8303, detach: false)
```
### <a name="send_msg_ready"></a> #send_msg_ready

**Parameter: TODO**

**Example:**
```ruby
client = TeeworldsClient.new

# TODO: generated documentation
client.send_msg_ready

client.connect('localhost', 8303, detach: false)
```
### <a name="send_enter_game"></a> #send_enter_game

**Parameter: TODO**

**Example:**
```ruby
client = TeeworldsClient.new

# TODO: generated documentation
client.send_enter_game

client.connect('localhost', 8303, detach: false)
```

### <a name="send_input"></a> #send_input(input = {})

**Parameter: Hash**

**Example:**
```ruby
client = TeeworldsClient.new

client.connect('localhost', 8303, detach: false)

loop do
  client.send_input(
        direction: -1,
        target_x: 10,
        target_y: 10,
        jump: rand(0..1),
        fire: 0,
        hook: 0,
        player_flags: 0,
        wanted_weapon: 0,
        next_weapon: 0,
        prev_weapon: 0)
end
```
### <a name="on_tick"></a> #on_tick(&block)

**Parameter: TODO**

**Example:**
```ruby
client = TeeworldsClient.new

# TODO: generated documentation
client.on_tick(&block)

client.connect('localhost', 8303, detach: false)
```
