require 'json'

hash = JSON.parse(IO.read('housekeeping/json/data.json'))

s = Source.first.source
m = Marc.new(s)
m.load_from_hash hash

#puts m

puts m.to_marc