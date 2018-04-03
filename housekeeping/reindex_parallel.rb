require "progress_bar"

@parallel_jobs = 10
@all_src = Source.all.count
@limit = @all_src / @parallel_jobs

jobnr = ARGV[0]
jobnr = 0 if !jobnr
jobnr = jobnr.to_i if jobnr

pb = ProgressBar.new(@limit)

#for jobnr in 0..@parallel_jobs
  offset = @limit * jobnr
  #Get the first record ID and last record id for this batch

  begin
    first_id = Source.order(:id).limit(@limit).offset(offset).select(:id).first.id  
    last_id = Source.order(:id).limit(@limit).offset(offset).select(:id).last.id
    puts "First #{jobnr} #{first_id}, last #{last_id}"
  rescue NoMethodError
    # This is the last one
    if jobnr == @parallel_jobs
      puts "Arrived to last job, offset was #{offset}, total src #{@all_src}"
    else
      # THis is an actual error!
      return -1
    end
  end
  
  count = 0
  Source.order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
    record = Source.find(sid.id)
    Sunspot.index record
    #record.reindex
    #Sunspot.commit
    pb.increment!
    count += 1
    if count == 50
      # In SOLR 5 we use the autocommit
      #Sunspot.commit
      count = 0
    end
    record = nil
  end
  
#  batch = 1
#  Source.find_in_batches(start: first_id, batch_size: 50) do |group|
#    Sunspot.index group
#    Sunspot.commit
#    pb.increment!(50)
#    batch += 1
#  end
  
#end
