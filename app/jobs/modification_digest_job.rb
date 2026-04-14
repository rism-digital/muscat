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
      begin_time = Time.now

      # get the last modified sources

      results = {}
      total_results = 0
      
      [Source, Work, Institution, Holding, Person, InventoryItem, LiturgicalFeast, Place, Publication, StandardTerm, StandardTitle, WorkNode].each do |model|
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
        end_time = Time.now
        duration = (end_time - begin_time).to_i
        human_readable = format("%02d:%02d:%02d", duration / 3600, (duration % 3600) / 60, duration % 60)
        time_msg = "It took Muscat #{duration} seconds to generate this report, in human time #{human_readable}"
        ModificationNotification.notify(user, total_results, results, time_msg).deliver_now
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
