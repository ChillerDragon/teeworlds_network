# teeworlds-client
A teeworlds 0.7 client library written in ruby

## Simple chat printing client

```ruby
require_relative 'lib/teeworlds-client'

client = TeeworldsClient.new(verbose: false)

# print all incoming chat messages
# the variable `msg` holds an instance of the class `ChatMessage` which has the following fields
#
# msg.mode
# msg.client_id
# msg.target_id
# msg.message
# msg.author.id
# msg.author.team
# msg.author.name
# msg.author.clan
client.hook_chat do |msg|
  puts "[chat] #{msg}"
end

# properly disconnect on ctrl+c
Signal.trap('INT') do
  client.disconnect
end

# connect to localhost and block the current thread
client.connect('localhost', 8303, detach: false)
```

## Print all network traffic

```ruby
require_relative 'lib/teeworlds-client'

client = TeeworldsClient.new(verbose: true)

# connect to localhost and block the current thread
client.connect('localhost', 8303, detach: false)
```

## Detach client (do not block the main thread)

```ruby
require_relative 'lib/teeworlds-client'

client = TeeworldsClient.new(verbose: true)

# connect to localhost and detach a background thread
client.connect('localhost', 8303, detach: true)

loop do
  # send a chat message every 5 seconds
  sleep 5
  client.send_chat('hello friends!')
end
```

## Set custom skin and other player infos

```ruby
require_relative 'lib/teeworlds-client'

client = TeeworldsClient.new(verbose: true)

# all keys are optional
# if not provided they will fall back to the default value
client.set_startinfo(
      name: "ruby gamer",
      clan: "",
      country: -1,
      body: "spiky",
      marking: "duodonny",
      decoration: "",
      hands: "standard",
      feet: "standard",
      eyes: "standard",
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
      color_eyes: 0)

# connect to localhost and block the current thread
client.connect('localhost', 8303, detach: false)
```
