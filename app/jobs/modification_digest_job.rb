class ModificationDigestJob < ApplicationJob
  queue_as :default
  
  def initialize
    super
  end
  
  def perform(*args)
    User.where(notification_type: :weekly).each do |user|
      # get the last modified sources
      
      results = {}
      
      Source.where(("updated_at" + "> ?"), 7.days.ago).order("updated_at DESC").each do |s|
      
        matcher = NotificationMatcher.new(s, user)
        if matcher.matches?
          results[s.id] = matcher.get_matches
        end
      end
      
      ModificationNotification.notify(user, results).deliver_now
    end
  end

end
