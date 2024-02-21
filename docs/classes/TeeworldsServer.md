# TeeworldsServer

### <a name="on_tick"></a> #on_tick(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is nil because there is no message payload.

**Example:**
```ruby
server = TeeworldsServer.new

server.on_tick do |context|
  # TODO: generated documentation
end

server.run('127.0.0.1', 8377)
```

### <a name="on_client_drop"></a> #on_client_drop(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is a [SvClientDrop](../classes/messages/SvClientDrop.md)

**Example:**
```ruby
server = TeeworldsServer.new

server.on_client_drop do |context|
  # TODO: generated documentation
end

server.run('127.0.0.1', 8377)
```

### <a name="on_input"></a> #on_input(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

TODO: generated documentation

**Example:**
```ruby
server = TeeworldsServer.new

server.on_input do |context|
  # TODO: generated documentation
end

server.run('127.0.0.1', 8377)
```

### <a name="on_enter_game"></a> #on_enter_game(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

TODO: generated documentation

**Example:**
```ruby
server = TeeworldsServer.new

server.on_enter_game do |context|
  # TODO: generated documentation
end

server.run('127.0.0.1', 8377)
```

### <a name="on_start_info"></a> #on_start_info(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

TODO: generated documentation

**Example:**
```ruby
server = TeeworldsServer.new

server.on_start_info do |context|
  # TODO: generated documentation
end

server.run('127.0.0.1', 8377)
```

### <a name="on_ready"></a> #on_ready(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

TODO: generated documentation

**Example:**
```ruby
server = TeeworldsServer.new

server.on_ready do |context|
  # TODO: generated documentation
end

server.run('127.0.0.1', 8377)
```

### <a name="on_info"></a> #on_info(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

TODO: generated documentation

**Example:**
```ruby
server = TeeworldsServer.new

server.on_info do |context|
  # TODO: generated documentation
end

server.run('127.0.0.1', 8377)
```

### <a name="on_emote"></a> #on_emote(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

TODO: generated documentation

**Example:**
```ruby
server = TeeworldsServer.new

server.on_emote do |context|
  # TODO: generated documentation
end

server.run('127.0.0.1', 8377)
```

### <a name="on_shutdown"></a> #on_shutdown(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

TODO: generated documentation

**Example:**
```ruby
server = TeeworldsServer.new

server.on_shutdown do |context|
  # TODO: generated documentation
end

server.run('127.0.0.1', 8377)
```

### <a name="on_rcon_cmd"></a> #on_rcon_cmd(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

TODO: generated documentation

**Example:**
```ruby
server = TeeworldsServer.new

server.on_rcon_cmd do |context|
  # TODO: generated documentation
end

server.run('127.0.0.1', 8377)
```

### <a name="on_rcon_auth"></a> #on_rcon_auth(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

TODO: generated documentation

**Example:**
```ruby
server = TeeworldsServer.new

server.on_rcon_auth do |context|
  # TODO: generated documentation
end

server.run('127.0.0.1', 8377)
```

### <a name="on_chat"></a> #on_chat(&block)

**Parameter: block [Block |[context](../classes/Context.md)|]**

context.message is nil because there is no message payload.

**Example:**
```ruby
server = TeeworldsServer.new

server.on_chat do |context|
  # TODO: generated documentation
end

server.run('127.0.0.1', 8377)
```


