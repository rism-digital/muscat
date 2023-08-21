
class MuscatCheckupReportJob < ApplicationJob
  queue_as :default
  
  def initialize(mdl = Source)
    super
    @model = mdl != nil && mdl.is_a?(Class) ? mdl : Source
  end

  def perform()
    begin_time = Time.now
  
    file_name = @model.is_a?(Source) ? "validation.log" : "#{@model.to_s.underscore.downcase}_validation.log"

    logger = Logger.new(File.new("#{Rails.root}/log/#{file_name}", 'w'))
    logger.datetime_format = 
    logger.formatter = proc do |severity, datetime, progname, msg|
      time = datetime.utc.strftime('%Y-%m-%d %H:%M:%SZ')
      "[#{time}] [#{'%8s' % severity}] #{msg}\n"
    end

    # Run the checkup function
    total_errors, total_validations, foreign_tag_errors, unknown_tags = MuscatCheckup.new(model: @model, logger: logger, process_exclusions: true).run_parallel

    end_time = Time.now
    message = "#{@model.to_s} report started at #{begin_time.to_s}, (execution time: #{end_time - begin_time} seconds)"
    
    HealthReport.notify(@model.to_s, message, total_errors, total_validations, foreign_tag_errors, unknown_tags).deliver_now
    
  end
  
end
