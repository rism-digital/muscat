require 'progress_bar'
pb = ProgressBar.new(Source.all.count)

Source.find_in_batches do |batch|

  batch.each do |s|
    modified = false
    pb.increment!
    s.marc.each_by_tag("595") do |t|
      tn = t.fetch_first_by_tag("a")
      
      #No love for the A tag
      if (tn && tn.content)
        tn.destroy_yourself
      end
      
      # Then move $u to $a
      tn = t.fetch_first_by_tag("u")
      next if !(tn && tn.content)
      
      modified = true
      
      t.add_at(MarcNode.new("source", "a", tn.content, nil), 0)
      t.sort_alphabetically
      tn.destroy_yourself

    end
    s.save if modified
  end
end