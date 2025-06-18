# grep "ORIG\|NEW" un000-output.txt | awk '{print $3}' | sort | uniq
# grep "ORIG\|NEW\|ADDED\|REMOVED" result | awk '{print $4}' | sort | uniq
# 
def diffize(model, id, marc1, marc2)
  
    lines1 = marc1.split("\n")
    lines2 = marc2.split("\n")

    diffs = Diff::LCS.sdiff(lines1, lines2)

    diffs.each do |diff|
    case diff.action
#    when '='
    when '!'
        #puts "Line #{diff.old_position + 1} changed:"
        puts "#{model}-#{id} ORIG #{diff.old_element}"
        puts "#{model}-#{id} NEW  #{diff.new_element}"
    when '-'
        # Line was removed
        puts "#{model}-#{id} REMOVED #{diff.old_element}"
    when '+'
        # Line was added
        puts "#{model}-#{id} ADDED   #{diff.new_element}"
    end
    end

end

def is_040_sane?(marc)
  t040 = marc["040"]
  return false if t040.empty?

  subtags = t040.map {|t| t.children.map(&:tag).sort.uniq}

  return subtags.sort.uniq.all?(['a', 'b', 'c', 'd', 'e'])
end

def megasave(s)
  
  marc1 = s.marc_source
  s.marc.load_source true

  model_marc = s.class.to_s.underscore.downcase

  #puts is_040_sane?(s.marc)
  #return if is_040_sane?(s.marc)

  _040_tag = s.marc["040"].first
  if !_040_tag
    _040_tag = MarcNode.new(model_marc, "040", "", "##")
    s.marc.root.children.insert(s.marc.get_insert_position("040"), _040_tag)
  end
  orig_tag = _040_tag.to_s

  # $a and $c must have a default value
  _040_tag.add_at(MarcNode.new(model_marc, "a", "DE-633", nil), 0)  if _040_tag["a"].empty?
  _040_tag.add_at(MarcNode.new(model_marc, "c", "DE-633", nil), 0)  if _040_tag["c"].empty?
  
  # $b and $d DO NOT NEED A DEFAULT VALUE
  #_040_tag.add_at(MarcNode.new(model_marc, "b", "eng", nil), 0)     if _040_tag["b"].empty?
  #_040_tag.add_at(MarcNode.new(model_marc, "d", "DE-633", nil), 0)  if _040_tag["d"].empty?

  # and $e needs one too
  _040_tag.add_at(MarcNode.new(model_marc, "e", "rismg", nil), 0)   if _040_tag["e"].empty?

  _040_tag.sort_alphabetically

  if orig_tag != _040_tag.to_s
    puts "#{s.marc.get_id} SAVING"

    PaperTrail.request(enabled: false) do
        s.suppress_reindex if s.respond_to? :suppress_reindex
        s.suppress_scaffold_marc if s.respond_to? :suppress_scaffold_marc
        s.suppress_recreate if s.respond_to? :suppress_recreate
        s.suppress_update_count if s.respond_to? :suppress_update_count
        s.suppress_update_77x if s.respond_to? :suppress_update_77x
        s.suppress_update_workgroups if s.respond_to? :suppress_update_workgroups
        s.save
        marc2 = s.marc_source
        diffize(s.class.to_s, s.id, marc1, marc2)
        puts "#{s.marc.get_id} DONE"
    end
  end

end

[Institution, InventoryItem, Holding, Publication, Person, Work, WorkNode].each do |model|
  model.find_in_batches do |batch|

    batch.each do |s|
      megasave(s)
    end

  end
end