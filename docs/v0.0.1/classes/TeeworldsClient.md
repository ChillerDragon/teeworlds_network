# TeeworldsClient

### <a name="on_disconnect"></a> #on_disconnect(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is nil because there is no message payload.

**Example:**
```ruby
client = TeeworldsClient.new

client.on_disconnect do |context|
  # TODO: generated documentation
end

client.connect('localhost', 8303, detach: false)
```

### <a name="on_connected"></a> #on_connected(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is nil because there is no message payload.

**Example:**
```ruby
client = TeeworldsClient.new

client.on_connected do |context|
  # TODO: generated documentation
end

client.connect('localhost', 8303, detach: false)
```

### <a name="on_rcon_line"></a> #on_rcon_line(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is a [RconLine](../classes/messages/RconLine.md)

**Example:**
```ruby
client = TeeworldsClient.new

client.on_rcon_line do |context|
  # TODO: generated documentation
end

client.connect('localhost', 8303, detach: false)
```

### <a name="on_auth_off"></a> #on_auth_off(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is nil because there is no message payload.

**Example:**
```ruby
client = TeeworldsClient.new

client.on_auth_off do |context|
  # TODO: generated documentation
end

client.connect('localhost', 8303, detach: false)
```

### <a name="on_auth_on"></a> #on_auth_on(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is nil because there is no message payload.

**Example:**
```ruby
client = TeeworldsClient.new

client.on_auth_on do |context|
  # TODO: generated documentation
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
  # TODO: generated documentation
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
  # TODO: generated documentation
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

TODO: generated documentation

**Example:**
```ruby
client = TeeworldsClient.new

client.on_client_info do |context|
  # TODO: generated documentation
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


### <a name="connect"></a> #connect(ip, port, options)

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
