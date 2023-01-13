require 'progress_bar'
require './housekeeping/works/functions'

pb = ProgressBar.new(Work.all.count )

# the delete the works
Work.find_in_batches do |batch|
    batch.each do |w|
        pb.increment!
        delete_work(w.id)
    end
end
