# Pass 1: add the 931

pb = ProgressBar.new(SourceWorkRelation.count)
SourceWorkRelation.find_each do |wr|
  
  s = wr.source
  #marc1 = s.marc_source

  s.marc.add_tag_with_subfields("931", "0": wr.work_id, "4": wr.relator_code)
#s.marc.import

  s.suppress_recreate
  s.suppress_reindex
  s.suppress_update_77x

  PaperTrail.request(enabled: false) do
    s.save
  end
  pb.increment!
  #marc2 = s.marc_source
  #diffize(s.id, marc1, marc2)
  #puts "#{s.marc.get_id} DONE"

end


pb = ProgressBar.new(SourceWorkRelation.select(:source_id).distinct.count)
SourceWorkRelation.select(:source_id).distinct.each do |s|
  ss = Source.find(s.source_id)
  begin
  PaperTrail.request(enabled: false) do
    ss.save
  end
  rescue ActiveRecord::RecordNotFound
    puts "oopsie"
  end
  pb.increment!
  ss = nil
end