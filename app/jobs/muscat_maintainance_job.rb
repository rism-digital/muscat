
class MuscatMaintainanceJob < ApplicationJob
    queue_as :default
    
    def initialize
      super
    end
    
    def perform(*args)
  
      begin_time = Time.now
    
      # Run the checkup function
      checkup = MuscatCheckup.new({jobs: 20, skip_validation: true, skip_dates: true, skip_unknown_tags: true})
      total_errors, total_validations, foreign_tag_errors, unknown_tags = checkup.run_parallel
  
      ap foreign_tag_errors

      end_time = Time.now
      message = "Source report started at #{begin_time.to_s}, (#{end_time - begin_time} seconds run time)"
      
      HealthReport.notify("Source", message, total_errors, total_validations, foreign_tag_errors, unknown_tags).deliver_now
      
    end
    
  end
  