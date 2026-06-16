# usage:
# ruby script.rb ids.txt

file_path = ARGV[0]

unless file_path && File.exist?(file_path)
  abort("Usage: ruby script.rb <file_with_ids>")
end

ids = File.readlines(file_path, chomp: true)
          .map(&:strip)
          .reject(&:empty?)

ids.each_with_index do |id, idx|
  item = InventoryItem.find(id)
  item.source_order = idx
  item.save!
end