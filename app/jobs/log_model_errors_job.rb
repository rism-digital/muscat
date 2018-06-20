class LogModelErrorsJob < ApplicationJob
  queue_as :default
  
  def perform(*args)
    errors = []
    Source.find_in_batches do |batch|

      batch.each do |s|
        begin
          s.marc.load_source true
        rescue
          AdminNotifications.notify("AUTO NOTIFICATION: Source #{s.id} has errors", s).deliver_now
        end
      end
    end
    
#    if errors.length > 0
      
#    end
    
  end
  
end
