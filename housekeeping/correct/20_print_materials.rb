f = Folder.find(92)

f.folder_items.each do |fi|
  s = fi.item
  s.marc.load_source false
  
  puts s.id
  t = s.marc.first_occurance("563", "a")
  puts "\t563\t\t#{t.content}"
  
  s.marc.each_by_tag("300") do |t|
    t.each_by_tag("a") do |tt|
      mat = t.fetch_first_by_tag("8")
      puts "\t300a\t#{mat.content}\t#{tt.content}"
    end
  end
  
end
