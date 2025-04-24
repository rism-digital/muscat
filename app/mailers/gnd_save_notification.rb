class GndSaveNotification < ApplicationMailer

  def notify(message, data = nil)
    
    @message = message
    @data = data
    
    mail(to: RISM::NOTIFICATION_EMAILS,
        from: "Muscat GND Nosey <#{RISM::DEFAULT_NOREPLY_EMAIL}>",
        subject: "Somebody saved something on GND")
  end

end
