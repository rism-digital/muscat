stop = false

page = 1

while !stop
  solr_response = Source.solr_search do
    #with :record_type, 1
    with  :"031t_filter", "Salve regina, mater misericordiae vita dulcedo"
    paginate :page => page
    #fulltext "", :fields => :"028a"
  end

  results = solr_response.results
  
  results.each do |s|
    puts s.id
  end
	
  page += 1
  stop = true if results.last_page?
end