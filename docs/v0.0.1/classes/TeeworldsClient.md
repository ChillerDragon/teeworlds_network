# TeeworldsClient

### <a name="on_snapshot"></a> #on_snapshot(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

TODO: generated documentation

**Example:**
```ruby
client = TeeworldsClient.new

client.on_snapshot do |context|
  # TODO: generated documentation
end

client.connect('localhost', 8303, detach: true)
```

### <a name="on_rcon_line"></a> #on_rcon_line(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

TODO: generated documentation

**Example:**
```ruby
client = TeeworldsClient.new

client.on_rcon_line do |context|
  # TODO: generated documentation
end

client.connect('localhost', 8303, detach: true)
```

### <a name="on_disconnect"></a> #on_disconnect(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

TODO: generated documentation

**Example:**
```ruby
client = TeeworldsClient.new

client.on_disconnect do |context|
  # TODO: generated documentation
end

client.connect('localhost', 8303, detach: true)
```

### <a name="on_connected"></a> #on_connected(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

TODO: generated documentation

**Example:**
```ruby
client = TeeworldsClient.new

client.on_connected do |context|
  # TODO: generated documentation
end

client.connect('localhost', 8303, detach: true)
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

client.connect('localhost', 8303, detach: true)
```

### <a name="on_chat"></a> #on_chat(&block)

**Parameter: block [Block |[ChatMessage](../classes/ChatMessage.md)|]**

Takes a block that will be called when the client receives a chat message.
The block takes one parameter of type [ChatMessage](../classes/ChatMessage.md).

**Example:**

```ruby
client = TeeworldsClient.new

client.on_chat do |msg|
  puts "[chat] #{msg}"
end

client.connect('localhost', 8303, detach: true)
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
  context.cancle
end

client.connect('localhost', 8303, detach: true)
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

client.connect('localhost', 8303, detach: true)

client.send_chat('hello world!')
```
