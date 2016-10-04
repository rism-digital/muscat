require 'progress_bar'

pb = ProgressBar.new(Source.count)
Source.find_in_batches(batch_size: 50) do |batch|

  batch.each do |record|
    begin
      m = record.marc
      m.load_source true
    rescue
      puts "Destroy #{record.id}"
      record.destroy
    end

    pb.increment!
  end

end
