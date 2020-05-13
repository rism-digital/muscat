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

    User.where(notification_type: :each).each do |user|
      matcher = NotificationMatcher.new(@object, user)

      if matcher.matches?
        ModificationNotification.notify(user, {@object.id => matcher.get_matches}).deliver_now
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