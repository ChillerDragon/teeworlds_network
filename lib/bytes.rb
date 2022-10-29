
# turn byte array into hex string
def str_hex(data)
  data.unpack("H*").first.scan(/../).join(' ').upcase
end

# turn hex string to byte array
def str_bytes(str)
  str.scan(/../).map{ |b| b.to_i(16) }
end

def bytes_to_str(data)
  data.unpack("H*").join('')
end

def get_byte(data, start = 0, num = 1)
  data[start...(start+num)].unpack("H*").join('').upcase
end
