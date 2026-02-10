Place.find_each(batch_size: 500) do |pl|
  src = pl.referring_sources.map(&:id).join(", ")
  puts "#{pl.id}\t#{pl.name}\t#{pl.country}\t#{pl.district}\t#{src}"
end