# teeworlds-client
A teeworlds 0.7 client library written in ruby

## Sample

Here a simple sample usage of the library.
Connecting a client to localhost on port 8303.
And printing out every chat message the server sends.
Also properly disconnect when the program is killed gracefully.

For more sample usages checkout the [examples/](examples/) folder.

```ruby
require_relative 'lib/teeworlds-client'

client = TeeworldsClient.new(verbose: false)

client.on_chat do |msg|
  puts "[chat] #{msg}"
end

Signal.trap('INT') do
  client.disconnect
end

client.connect('localhost', 8303, detach: false)
```

## Documentation

Checkout [docs/01.md](docs/01.md) for a full library documentation.
