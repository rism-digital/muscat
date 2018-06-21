class HealthReport < ApplicationMailer

  def notify(model, message, errors)
    
    @message = message
		@model = model
		@errors = errors
    
    mail(to: RISM::NOTIFICATION_EMAIL,
        name: "Muscat Admin Notificator",
        subject: "Muscat Health Report: #{model}")
  end

end
