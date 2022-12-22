types = {
  "libretto_edition_content": [
    "Print"
  ], 
  "theoretica_edition_content": [
    "Print"
  ], 
  "edition": [
    "Print"
  ], 
  "composite_volume": [
    "Composite"
  ], 
  "libretto_source": [
    "Autograph manuscript", 
    "Possible autograph manuscript", 
    "Partial autograph", 
    "Manuscript copy", 
    "Manuscript copy with autograph annotations", 
    "Additional printed material"
  ], 
  "collection": [
    "Autograph manuscript", 
    "Possible autograph manuscript", 
    "Partial autograph", 
    "Manuscript copy", 
    "Manuscript copy with autograph annotations", 
    "Additional printed material"
  ], 
  "theoretica_edition": [
    "Print"
  ], 
  "source": [
    "Autograph manuscript", 
    "Possible autograph manuscript", 
    "Partial autograph", 
    "Manuscript copy", 
    "Manuscript copy with autograph annotations", 
    "Additional printed material"
  ], 
  "libretto_edition": [
    "Print"
  ], 
  "edition_content": [
    "Print"
  ], 
  "theoretica_source": [
    "Autograph manuscript", 
    "Possible autograph manuscript", 
    "Partial autograph", 
    "Manuscript copy", 
    "Manuscript copy with autograph annotations", 
    "Additional printed material"
  ]
}

Source.find_in_batches do |batch|

    batch.each do |sid|
        s = Source.find(sid.id)
        s.marc.load_source false
        s.marc.each_by_tag("593") do |t|
    
            t.fetch_all_by_tag("a").each do |tn|
                next if !tn || !tn.content

                if !types[s.get_record_type].include?(tn.content)
                    puts "#{s.id}\t#{s.get_record_type}\t#{tn.content}"
                end

            end
        end

        s = nil
    end

end