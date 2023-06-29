
class MuscatCheckupReportJob < ApplicationJob
  queue_as :default
  
  def initialize
    super
  end

  def perform(*args)

    begin_time = Time.now
  
    logger = Logger.new(File.new("#{Rails.root}/log/validation.log", 'w'))
    logger.datetime_format = 
    logger.formatter = proc do |severity, datetime, progname, msg|
      time = datetime.utc.strftime('%Y-%m-%d %H:%M:%SZ')
      "[#{time}] [#{'%8s' % severity}] #{msg}\n"
    end

    # Run the checkup function
    total_errors, total_validations, foreign_tag_errors, unknown_tags = MuscatCheckup.new(logger: logger, process_exclusions: true).run_parallel

    end_time = Time.now
    message = "Source report started at #{begin_time.to_s}, (#{end_time - begin_time} seconds run time)"
    
    HealthReport.notify("Source", message, total_errors, total_validations, foreign_tag_errors, unknown_tags).deliver_now
    
  end
  
end
