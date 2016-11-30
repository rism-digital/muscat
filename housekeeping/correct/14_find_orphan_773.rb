require 'progress_bar'

parent_ids = {}
count = 0

pb = ProgressBar.new(Source.where.not(source_id: nil).count)
Source.where.not(source_id: nil).find_in_batches(batch_size: 50) do |batch|

  batch.each do |record|
    
    found_id = nil
    parent = record.parent_source
    
    parent.marc.each_data_tag_from_tag("774") do |tag|
      subfield = tag.fetch_first_by_tag("w")
      next if !subfield || !subfield.content
      found_id = subfield.content.to_i if subfield.content.to_i == record.id
    end

    if !found_id
      if !parent_ids.include?(parent.id)
        parent_ids[parent.id] = []
      end
      parent_ids[parent.id] << record.id
    end

    pb.increment!
    count += 1
  end

  #break if count > 10000
end

#$stderr.puts parent_ids.ai(plain: true)

File.open('missing_774_log.txt', 'w') do |f|
  f.write parent_ids.ai(plain: true)
end