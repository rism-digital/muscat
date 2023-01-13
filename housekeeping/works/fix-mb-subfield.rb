require 'progress_bar'

pb = ProgressBar.new(Work.all.count)

Work.find_in_batches do |batch|

    batch.each do |w|

        pb.increment!

        modified = false
  
        w.marc.each_by_tag("024") do |t|
          t2 = t.fetch_first_by_tag("2")
          if t2 and t2.content and t2.content == "mb"
            t2.content = "MBZ"            
            modified = true   
          end
        end
        
        w.save if modified
    end
end