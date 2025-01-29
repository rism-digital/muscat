abusive_holdings = Holding.left_joins(:source).where("sources.source_id IS NOT NULL")
puts "⚠️  There are #{abusive_holdings.count} holdings that are connected to a child record"
abusive_holdings.delete_all

#.each {|h| puts h.lib_siglum if h.source.holdings.count > 1}