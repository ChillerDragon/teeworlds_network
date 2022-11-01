# teeworlds-client
A teeworlds 0.7 client library written in ruby

```ruby
require_relative 'lib/teeworlds-client'

client = TwClient.new(verbose: false)

client.hook_chat do |msg|
  puts "chat: #{msg}"
end

client.connect('localhost', 8303)
```
