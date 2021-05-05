class ModificationDigestJob < ApplicationJob
  queue_as :default
  
  def initialize(period = :weekly)
    super
    set_period(period)
  end
  
  def perform(*args)
    
    ## For compatibility between crono and delayed job
    set_period(args[0]) if !args.empty?
    
    User.where(notification_type: @period).each do |user|
      # get the last modified sources
      
      results = {}
      total_results = 0
      
      [Source, Work].each do |model|
        model.where(("updated_at" + "> ?"), @days.days.ago).order("updated_at DESC").each do |s|
        
          matcher = NotificationMatcher.new(s, user)

          matcher.get_matches.each do |match|
            results[model.to_s.downcase] = {} if !results[model.to_s.downcase]
            results[model.to_s.downcase][match] = [] if !results[model.to_s.downcase][match]

            results[model.to_s.downcase][match] << s
            total_results += 1
          end

        end
      end

      if !results.empty?
        ModificationNotification.notify(user, total_results, results).deliver_now
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
