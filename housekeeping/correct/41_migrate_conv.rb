source_list = {
  990012923 => [58476, 59576, 68055, 306728, 306874, 51001942, 47622],
  990005014 => [20773, 45368, 46517, 48702, 48725, 50093, 123288, 156222, 236820, 243180, 271893, 274377, 20811],
  990055008 => [20839, 156683, 214588, 217189, 217190, 217195, 242879, 262110, 273337, 214618],
  1001051142 => [71287, 72027, 330110],
  990020966 => [73553, 73551],
  992006840 => [80817, 81016, 81723, 81726, 81814, 83116, 159806, 250197, 273326, 282592, 291094, 295246, 297821, 
                297854, 300963, 308699, 310533, 310775, 310786, 310787, 310788, 310790, 310799, 310871, 310885, 310901, 
                310904, 310905, 310906, 310936, 310949, 310953, 310956, 310961, 310965, 310976, 310982, 310986, 310990, 
                311748, 311764, 311829, 312929, 313329, 313616, 314984, 316304, 316308, 316310, 316313, 316315, 316320, 
                316322, 316327, 316747, 316925, 316931, 316941, 329218, 329219, 329302, 329540, 329569, 316927],
  990043327 => [173956, 167330],
  992001743 => [316927, 310775],
  990071584 => [316927, 273326],
  991019245 => [316927, 297853],
  991019246 => [316927, 297854],
  992001894 => [316927, 310990],
  992001753 => [316927, 310786],
  992001754 => [316927, 310787],
  992005357 => [316927, 314984],
  992006721 => [316927, 316747],
  990039630 => [51002073, 51002074, 51002075, 51002076, 51002077, 51002078, 51002079, 51002080, 51002081, 51002082, 51002083, 51002084, 51002085, 51002086, 152642]
}

source_list.each do |fsrc, holdings|
  
  first_source = Source.find(fsrc)
  
  new_source = Source.new
  marc = MarcSource.new(File.read("#{Rails.root}/config/marc/#{RISM::MARC}/source/000_collection.marc"), MarcSource::RECORD_TYPES[:collection])
  
  marc.first_occurance("852").destroy_yourself
  marc.first_occurance("700").destroy_yourself
  
  new_852 = Holding.find(holdings.first).marc.first_occurance("852").deep_copy
  marc.root.add_at(new_852, marc.get_insert_position("852") )
  
  if first_source.marc.first_occurance("100")
    new_100 = first_source.marc.first_occurance("100").deep_copy
    marc.root.add_at(new_100, marc.get_insert_position("100") )
  end
  
  if first_source.marc.first_occurance("240")
    new_100 = first_source.marc.first_occurance("240").deep_copy
    marc.root.add_at(new_100, marc.get_insert_position("240") )
  end
  
  if first_source.marc.first_occurance("710")
    new_100 = first_source.marc.first_occurance("710").deep_copy
    marc.root.add_at(new_100, marc.get_insert_position("710") )
  end
  
  if first_source.marc.first_occurance("700")
    new_100 = first_source.marc.first_occurance("700").deep_copy
    marc.root.add_at(new_100, marc.get_insert_position("700") )
  end
  
  if first_source.marc.first_occurance("245")
    new_100 = first_source.marc.first_occurance("245").deep_copy
    marc.root.add_at(new_100, marc.get_insert_position("245") )
  end
  
  new_source.marc = marc
  new_source.record_type = MarcSource::RECORD_TYPES[:collection]
  new_source.save
  
  puts new_source.id
  
  holdings.each do |h|
    holding = Holding.find(h)
    
    # First step, migrate away 563 $u
    holding.marc.each_by_tag("563") do |tag|
      tag.each_by_tag("u") do |id|
        
        n963 = MarcNode.new("holding", "963", "", '##')
        n963.add_at(MarcNode.new("holding", "u", id.content, nil), 0 )
      
        holding.marc.root.add_at(n963, holding.marc.get_insert_position("963") )
        
        id.destroy_yourself
      end
    end
    
    ## Now add the 973 reference to the convolutum
    n973 = MarcNode.new("holding", "973", "", '##')
    n973.add_at(MarcNode.new("holding", "u", new_source.id.to_s, nil), 0 )
    holding.marc.root.add_at(n973, holding.marc.get_insert_position("973") )
    
    #puts holding.marc.to_marc
    #puts "saving #{holding.id}"
    
    holding.save
    # make sure the links are updated
    holding.save!
    
  end
  
end