    class MuscatMaintenanceReport < ApplicationMailer

    def notify(message, base_model, saved_source_count, models, unsavable_sources)
        
        @message = message
        @saved_source_count = saved_source_count
        @models = models
        @unsavable_sources = unsavable_sources
        @base_model = base_model
        

        mail(to: RISM::NOTIFICATION_EMAILS,
        from: "#{RISM::DEFAULT_EMAIL_NAME} Periodic Maintenance Bot <#{RISM::DEFAULT_NOREPLY_EMAIL}>",
        subject: "Muscat Maintenance Report for #{@base_model}")
    end

    end
