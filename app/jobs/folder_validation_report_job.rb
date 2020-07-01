
class FolderValidationReportJob < ApplicationJob

    def initialize(id, user)
        @id = id
        @user_id = user
    end

    def enqueue(job)
        job.parent_id = @id
        job.parent_type = "Folder"
        job.save!
    end

    def perform()
        
        user = User.find(@user_id)

        folder = Folder.find(@id)
        begin_time = Time.now
    
        # Run the checkup function
        total_errors, total_validations, foreign_tag_errors, unknown_tags = MuscatCheckup.new(folder: folder).run_parallel
  
        end_time = Time.now
        message = "Source report started at #{begin_time.to_s}, (#{end_time - begin_time} seconds run time)"
      
        FolderValidationReport.notify("Source", message, total_errors, total_validations, foreign_tag_errors, unknown_tags, user).deliver_now
      
    end
    
    def destroy_failed_jobs?
        false
    end

    def max_attempts
        1
    end

    def queue_name
        'folders'
    end

end
+config.action_mailer.delivery_method = :sendmail
+    config.proxy = 'http://http-proxy.sbb.spk-berlin.de:3128'