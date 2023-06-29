class ExportReadyNotification < ApplicationMailer

    def notify(email, file, name)
      
      @file = file
      @name = name
      
      mail(to: email,
        from: "#{RISM::DEFAULT_EMAIL_NAME} Export <#{RISM::DEFAULT_NOREPLY_EMAIL}>",
        subject: "File #{file} ready for download (#{@name})")
    end
  
  end
  