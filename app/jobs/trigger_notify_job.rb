class TriggerNotifyJob < ProgressJob::Base
  
  def initialize(object)
    @object = object
  end
  
  def enqueue(job)
    if @object
      job.parent_id = @object.id
      job.parent_type = @object.class
      job.save!
    end
  end

  def perform
    return if !@object

    User.where(notification_type: :every).each do |user|
      results = {}
      total_results = 0
      model = @object.class.to_s.downcase
      matcher = NotificationMatcher.new(@object, user)

      matcher.get_matches.each do |match|
        results[model] = {} if !results[model]
        results[model][match] = [] if !results[model][match]

        results[model][match] << @object
        total_results += 1
      end
      
      if !results.empty?
        ModificationNotification.notify(user, total_results, results).deliver_now
      end

    end
    
  end
  
  def destroy_failed_jobs?
    false
  end

  def max_attempts
    1
  end

  def queue_name
    'triggers'
  end
end