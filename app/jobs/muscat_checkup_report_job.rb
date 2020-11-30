
class MuscatCheckupReportJob < ApplicationJob
  queue_as :default
  
  def initialize
    super
  end

  def perform(*args)

    begin_time = Time.now
  
    logger = Logger.new("#{Rails.root}/log/MuscatCheckupReportJob.log")
    logger.datetime_format = 
    logger.formatter = proc do |severity, datetime, progname, msg|
      time = datetime.strftime('%Y-%m-%d %H:%M:%S')
      "[#{time}] [#{'%8s' % severity}] #{msg}\n"
    end

    # Run the checkup function
    total_errors, total_validations, foreign_tag_errors, unknown_tags = MuscatCheckup.new(logger: logger).run_parallel

    end_time = Time.now
    message = "Source report started at #{begin_time.to_s}, (#{end_time - begin_time} seconds run time)"
    
    HealthReport.notify("Source", message, total_errors, total_validations, foreign_tag_errors, unknown_tags).deliver_now
    
  end
  
end
