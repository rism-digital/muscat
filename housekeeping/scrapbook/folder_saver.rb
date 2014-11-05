fi = nil
results = Source.first(5000)

f = Folder.create(:name => "Folder #{Folder.count}", :folder_type => "Source")

#Benchmark.bm(7) do |x| x.report("Add Items INSERT") { results.each { |s| f.add_item(s) } } end

Benchmark.bm(7) do |x| x.report("Add Items IMPORT") {
  h = []
  results.each { |r| h << FolderItem.new(:folder_id => f.id, :item => r) }
  FolderItem.import(h)
}
end

# Full reindex
#Benchmark.bm(7) do |x| x.report("Index") { FolderItem.index } end
#Benchmark.bm(7) do |x| x.report("Commit") { Sunspot.commit } end

# Partial reindex
f2 = Folder.find(f.id)
Benchmark.bm(7) do |x| x.report("Index 2") { Sunspot.index f2.folder_items } end
Benchmark.bm(7) do |x| x.report("Commit 2") { Sunspot.commit } end
  
f2 = Folder.find(f.id)
Benchmark.bm(7) do |x| x.report("Index 3") { Sunspot.index f2.folder_items } end
Benchmark.bm(7) do |x| x.report("Commit 3") { Sunspot.commit } end