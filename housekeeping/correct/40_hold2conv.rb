pointing_holdings = {}
  
Holding.where('marc_source REGEXP "=563[^\n]*\[[.$.]]u"').each do |h|

  source_ids = []

  h.marc.each_by_tag("563") do |tag|
    tag.each_by_tag("u") do |id|
      #puts "#{h.id} #{id.content}"
      source_ids << id.content.to_i
      pointing_holdings[id.content] = [] if !pointing_holdings.include?(id.content)
      pointing_holdings[id.content] << h.id
      #break
    end
  end

#  puts "#{h.id} #{source_ids.count}" if source_ids.count > 1



end

pointing_holdings.each do |k, v|
  #next if v.count > 1

  s = Source.find(k)

  #puts "#{s.id} #{s.record_type} #{s.child_sources.count} #{s.lib_siglum} #{s.shelf_mark}"
  print "#{s.id} =>"

  first_siglum = ""

  holdings = []

  v.each do |ho|
    hu = Holding.find(ho)
    
    siglum = ""
    hu.marc.each_by_tag("852") do |tag|
      tag.each_by_tag("c") do |id|
        siglum = id.content if id && id.content
      end
    end
    
    
    
    #puts "* #{ho} #{hu.lib_siglum} #{siglum}"
    print "#{ho}, "
    first_siglum = hu.lib_siglum
  end
  
  begin
    s.holdings.each do |sho|
      if sho.lib_siglum == first_siglum
      
        sho.marc.each_by_tag("852") do |tag|
          tag.each_by_tag("c") do |id|
            #puts "X #{sho.id} #{sho.lib_siglum} #{id.content}" if id && id.content
            print "#{sho.id}, "
          end
        end
      
      end
    end
  rescue
    puts "ops"
  end
  puts
  
end