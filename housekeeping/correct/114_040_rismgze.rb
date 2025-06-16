# grep "ORIG\|NEW" un000-output.txt | awk '{print $3}' | sort | uniq
# grep "ORIG\|NEW\|ADDED\|REMOVED" result | awk '{print $4}' | sort | uniq
# 
def diffize(id, marc1, marc2)
  
    lines1 = marc1.split("\n")
    lines2 = marc2.split("\n")

    diffs = Diff::LCS.sdiff(lines1, lines2)

    diffs.each do |diff|
    case diff.action
#    when '='
    when '!'
        #puts "Line #{diff.old_position + 1} changed:"
        puts "#{id} ORIG #{diff.old_element}"
        puts "#{id} NEW  #{diff.new_element}"
    when '-'
        # Line was removed
        puts "#{id} REMOVED #{diff.old_element}"
    when '+'
        # Line was added
        puts "#{id} ADDED   #{diff.new_element}"
    end
    end

end

def is_040_sane?(marc)
  t040 = marc["040"]
  return false if !t040

  subtags = t040.children.map(&:tag)

  return subtags.all?(['a', 'b', 'c', 'd', 'e'])
end

def megasave(s)
  
  marc1 = s.marc_source
  s.marc.load_source true
  save = true #!!!! fixme

  model_marc = s.class.to_s.downcase.underscore

  _040_tage = s.marc.first_occurance("040", "e")
  return if _040_tage && _040_tage.content == "rismg"

  _040_tag = s.marc.first_occurance("040")
  if !_040_tag
    _040_tag = MarcNode.new(model_marc, "040", "", "##")
    s.marc.root.children.insert(s.marc.get_insert_position("040"), _040_tag)
  end

  _040_tag.add_at(MarcNode.new(model_marc, "e", "rismg", nil), 0)
  _040_tag.sort_alphabetically

  if save
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
        diffize(s.id, marc1, marc2)
        puts "#{s.marc.get_id} DONE"
    end
  end

end

InventoryItem.find_in_batches do |batch|

  batch.each do |s|
    megasave(s)
  end

end