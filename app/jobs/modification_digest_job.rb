class ModificationDigestJob < ApplicationJob
  queue_as :default
  
  def initialize(period = :weekly)
    super
    set_period(period)
  end
  
  def perform(*args)
    results_by_criteria = {}
    ## For compatibility between crono and delayed job
    set_period(args[0]) if !args.empty?
    
    User.where(notification_type: @period).each do |user|
      # get the last modified sources
      
      results = {}
      
      Source.where(("updated_at" + "> ?"), @days.days.ago).order("updated_at DESC").each do |s|
      
        matcher = NotificationMatcher.new(s, user)
        if matcher.matches?
          results[s] = matcher.get_matches
        end
      end
      
      if !results.empty?
        # Flip them from source -> criteria to criterias-> source
        results.map { |source_id, criterias| criterias.map { |criteria| results_by_criteria.include?(criteria) ? results_by_criteria[criteria] << source_id : results_by_criteria[criteria] = [source_id]} }
        ModificationNotification.notify(user, results, results_by_criteria).deliver_now
      end
    end
  end

  private
  def set_period(period)
    period = period.to_sym if period.is_a?(String)
    @period = period
    @period = :weekly if ![:daily, :weekly].include?(@period)
    @days = @period == :weekly ? 7 : 1
    puts "Set #{@period} for #{@days} days"
  end

end
