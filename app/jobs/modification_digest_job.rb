class ModificationDigestJob < ApplicationJob
  queue_as :default
  
  def initialize(period = :weekly)
    super
    set_period(period)
  end
  
  def perform(*args)
    ## For compatibility between crono and delayed job
    set_period(args[0]) if !args.empty? && args[0].is_a?(Symbol)
    
    User.where(notification_type: @period).each do |user|
      # get the last modified sources
      
      results = {}
      
      Source.where(("updated_at" + "> ?"), @days.days.ago).order("updated_at DESC").each do |s|
      
        matcher = NotificationMatcher.new(s, user)
        if matcher.matches?
          results[s.id] = matcher.get_matches
        end
      end
      
      ModificationNotification.notify(user, results).deliver_now if !results.empty?
    end
  end

  private
  def set_period(period)
    @period = period
    @period = :weekly if ![:daily, :weekly].include?(@period)
    @days = @period == :weekly ? 7 : 1
    puts "Set #{@period} for #{@days} days"
  end

end
