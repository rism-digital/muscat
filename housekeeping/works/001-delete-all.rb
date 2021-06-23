require 'progress_bar'
require './housekeeping/works/functions'

pb = ProgressBar.new(Work.all.count * 2)

# first delete the work-to-work links
Work.find_in_batches do |batch|
    batch.each do |w|
        pb.increment!
        delete_work_links(w.id)
    end
end

# the delete the works
Work.find_in_batches do |batch|
    batch.each do |w|
        pb.increment!
        delete_work(w.id)
    end
end
