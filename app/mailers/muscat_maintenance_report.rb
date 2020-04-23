    class MuscatMaintenanceReport < ApplicationMailer

    def notify(message, saved_sources, auth_file_count, unsavable_sources)
        
        @message = message
        @saved_sources = saved_sources
        @auth_file_count = auth_file_count
        @unsavable_sources = unsavable_sources
        

        mail(to: RISM::NOTIFICATION_EMAIL,
        from: "#{RISM::DEFAULT_EMAIL_NAME} Periodic Maintenance Bot <#{RISM::DEFAULT_NOREPLY_EMAIL}>",
        subject: "Muscat Maintenance Report")
    end

    end
