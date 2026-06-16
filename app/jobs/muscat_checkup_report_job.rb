
class MuscatCheckupReportJob < ApplicationJob
  queue_as :default
  
  def initialize(mdl = Source)
    super
    @model = mdl != nil && mdl.is_a?(Class) ? mdl : Source
  end

  def perform()
    begin_time = Time.now
  
    # For compatibility with older versions, validation.log is always for sources
    file_name = @model.is_a?(Source) ? "validation.log" : "#{@model.to_s.underscore.downcase}_validation.log"

    logger = Logger.new(File.new("#{Rails.root}/log/#{file_name}", 'w'))
    logger.datetime_format = 
    logger.formatter = proc do |severity, datetime, progname, msg|
      #time = datetime.utc.strftime('%Y-%m-%d %H:%M:%SZ')
      #"[#{time}] [#{'%8s' % severity}] #{msg}\n"
      "#{msg}\n"
    end

    # Run the checkup function
    total_errors, total_validations, foreign_tag_errors, unknown_tags = MuscatCheckup.new(model: @model, logger: logger, process_exclusions: true).validate_parallel

    end_time = Time.now
    duration = (end_time - begin_time).to_i
    human_readable = format("%02d:%02d:%02d", duration / 3600, (duration % 3600) / 60, duration % 60)
    message = "#{@model.to_s} report started at #{begin_time.to_s}, (execution time: #{duration} seconds, or in human terms: #{human_readable})"
    
    HealthReport.notify(@model.to_s, message, total_errors, total_validations, foreign_tag_errors, unknown_tags).deliver_now
    
  end
  
end
