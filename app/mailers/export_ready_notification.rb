class ExportReadyNotification < ApplicationMailer

    def notify(email, file)
      
      @file = file
      
      mail(to: email,
        from: "#{RISM::DEFAULT_EMAIL_NAME} Export <#{RISM::DEFAULT_NOREPLY_EMAIL}>",
        subject: "File #{file} ready for download")
    end
  
  end
  