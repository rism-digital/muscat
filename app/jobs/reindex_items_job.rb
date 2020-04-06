class ReindexItemsJob < ProgressJob::Base
  
  # We could pass direcrly and object here, but sometimes the object is
  # deleted before the job is run. In this case when unmarshalling it from
  # the database it will theow an error we cannot catch here in the job.
  # On the other hand, using id + class we can run a find and manage the error
  def initialize(parent_obj_id, parent_obj_class, relation = "referring_sources", offset = 0)
    @parent_obj_id = parent_obj_id
    @parent_obj_class = parent_obj_class
    @relation = relation
    @offset = offset
  end
  
  def enqueue(job)
    return if !@parent_obj_id || !@parent_obj_class

    # We want a class here
    return if !@parent_obj_class.is_a? Class

    job.parent_id = @parent_obj_id
    job.parent_type = @parent_obj_class
    job.save!

  end

  def perform
    # Sometimes, the record is deleted before the job is run
    begin
      parent_obj = @parent_obj_class.send("find", @parent_obj_id)
    rescue ActiveRecord::RecordNotFound
      return # Just exit
    end
    
    update_progress_max(-1)
    items = parent_obj.send(@relation)

    # if we are a sub-job or just less than 200 items
    if @offset > 0 || items.count < 200
      reindex_batch(items)
    else
      # Split the job into subjobs
      enqueue_new_jobs
    end
    
  end
  
  def destroy_failed_jobs?
    false
  end
  
  def max_attempts
    1
  end
  
  def queue_name
    'reindex'
  end

  private
  MAX_SLICES = 10

  def reindex_batch(items)

    # use only a chunk
    if @offset > 0
      limit = items.count / (MAX_SLICES - 1)
      start_from = limit * (@offset - 1)
      items = items.order(:id).offset(start_from).limit(limit)
      job_id = "[#{@offset}] "
    end

    update_stage("#{job_id}Processing #{items.count} items for #{@relation}")
    update_progress_max(items.count)
    progress = 1
    items.each do |item|
      Sunspot.index item
      update_stage_progress("#{job_id}Reindexing records #{progress}/#{items.count}", step: 20) if progress % 20 == 0
      progress += 1
    end
    Sunspot.commit
  end

  def enqueue_new_jobs
    (1..MAX_SLICES).each do |n|
      Delayed::Job.enqueue(ReindexItemsJob.new(@parent_obj_id, @parent_obj_class, @relation, n), :queue => 'sub_reindex')
    end
  end

end
