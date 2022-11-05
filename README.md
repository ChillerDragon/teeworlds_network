# teeworlds-client
A teeworlds 0.7 client library written in ruby

## Sample

Here a simple sample usage of the library.
Connecting a client to localhost on port 8303.
Acting as a simple chat bot.
Also properly disconnect when the program is killed gracefully.

For more sample usages checkout the [examples/](examples/) folder.

```ruby
require_relative 'lib/teeworlds-client'

client = TeeworldsClient.new(verbose: false)

client.on_chat do |msg|
  # note use `next` instead of `return` in the block
  next if msg.message[0] == '!'

  case msg.message[1..]
  when 'ping' then client.send_chat('pong')
  when 'whoami' then client.send_chat("You are: #{msg.author.name}")
  when 'list' then client.send_chat(client.game_client.players.values.map(&:name).join(', '))
  else client.send_chat('Unkown command! Commands: !ping, !whoami, !list')
  end
end

# properly disconnect on ctrl+c
Signal.trap('INT') do
  client.disconnect
end

# connect to localhost and block the current thread
client.connect('localhost', 8303, detach: false)
```

## Documentation

Checkout [docs/01.md](docs/01.md) for a full library documentation.
