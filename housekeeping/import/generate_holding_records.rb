offset = (ARGV[0].nil? ? 0 : ARGV[0]).to_i
number = (ARGV[1].nil? ? 10000000 : ARGV[1]).to_i
from = ("%05d" % (offset))
to = ("%05d" % (offset + number))

sources = Source.find(:all, :order => "id", :limit => number, :offset => offset,:conditions => [ "record_type <> 2"] )

i = 1
sources.each do |ms_iterator|

  source = Source.find(ms_iterator.id)	

  puts "#{i.to_s} (#{(i + offset).to_s})" if i % 100 == 0
  #output = manuscript.generate([:png])

  modified = false

  holdings = source.marc.by_tags(["852"])
  holdings.each do |holding_tag|
    
    #arc = MarcSource.new()
    marc = MarcSource.new(File.read( "#{Rails.root}/housekeeping/import/holding.marc" ) )
    # load the source but without resolving externals
    marc.load_source(false)
    p marc 
    # Create the 004 tag for link with the ms
    marc.root.add( MarcNode.new("source", "004", source.id, nil) ) 
    p marc
    # Extract the 852 tag from ms
    tag_852 = holding_tag.deep_copy
    #tag_852.parent = nil
    
    #... and place it into the Marc record
    ip = marc.get_insert_position("852")
    marc.root.children.insert(ip, tag_852)
    
    # Force an import, this will resolve all the externals and put them into @all_foreign_associations
    marc.import
    
    # Update or create a new holding record
    holding = Source.new(:wf_owner => 1, :wf_stage => "published", :wf_audit => "approved")
    # associate the marc
    holding.marc = marc

    # Since MS is not saved yet, get the siglum from 852
    user = nil
    siglum = tag_852.fetch_first_by_tag("a")
    #user = User.find_by_login(siglum.content) if siglum.content
    
    # Set the user
    if user
      holding.wf_owner = user.id 
    end

    # Save holding record
    holding.suppress_reindex
    #holding.suppress_create_incipit
    holding.save
    holding_tag.destroy_yourself
    
    modified = true

  end
  
  if source.source
    # Set the 246 tag if this is a reissue of a print
    parent_245 = source.source.marc.first_occurance("245")
  
    if parent_245    
      new_246 = MarcNode.new("246", "", "10")
    
      count = 0
      parent_245.each do |tag|
      
        next if tag.tag == "245"
      
        if tag.tag = "a"
          tag.content = "[previous entry:] " + tag.content
        end
      
        new_246.add_at(MarcNode.new(tag.tag, tag.content, nil), count)
        count = count + 1
      end
    
      new_246.sort_alphabetically
  
      #ms.marc.root.children.insert(pi, new_246)
      source.marc.root.add_at(new_246, source.marc.get_insert_position("246"))
      
      modified = true
    end
  end
  
  source.suppress_reindex
  #source.suppress_create_incipit  
  source.save if modified
  
  source = nil

  i += 1
end
