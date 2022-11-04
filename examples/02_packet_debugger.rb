# Prints out all network traffic

require_relative 'lib/teeworlds-client'

client = TeeworldsClient.new(verbose: true)

# connect to localhost and block the current thread
client.connect('localhost', 8303, detach: false)