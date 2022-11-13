# Context

This class is the callback context.
When you hook into methods using a ``on_*`` method you can access its context.
This gives you the ability to read and modify the data before the default behavior processes it.
Or skip the default behavior and implement your own logic.

### #cancle

Call the ``cancle()`` on the context object to not run any default code for that event.

```ruby
client.on_map_change do |context|
  # do nothing when a map change packet comes in
  # skips the send ready packet code
  context.cancle
end
```

### @client [[TeeworldsClient](../classes/TeeworldsClient.md)]

Access the network client to send packets.

**Example:**

Reimplement your on on_connected logic and cancle the default one

```ruby
client.on_connected do |ctx|
  ctx.client.send_msg_start_info
  ctx.cancle
end
```

### @data [Hash]

This hash holds all the current data. They keys might vary depending on the current context.
You can read and write those values. If you set an unused key the program will panic.

**Example:**

Here an example to see what keys you are given for a client info event.

```ruby
client = TeeworldsClient.new

client.on_client_info do |context|
  p context.data.keys
  # [:player, :chunk]
end
```

Here an example to modify all incoming player info to rename all player objects to yee.
Which is a bit weird but shows the power of the modding api.

```ruby
client = TeeworldsClient.new

client.on_client_info do |context|
  context.data[:player].name = 'yee'
end
```