require 'progress_bar'

pb = ProgressBar.new(Work.all.count)

count = 0
Work.find_in_batches do |batch|

    batch.each do |w|

        pb.increment!

        modified = false
  
        w.marc.load_source false
        status = w.marc.get_link_status
        if status != 0
            modified = true 
            count += 1
        end
        
        w.save if modified
    end
end

puts "#{count} works fixed"