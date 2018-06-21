class HealthReport < ApplicationMailer

  def notify(model, message, errors, validations)
    
    @message = message
		@model = model
		@errors = errors
		@validations = validations
    
    mail(to: RISM::NOTIFICATION_EMAIL,
        name: "Muscat Admin Notificator",
        subject: "Muscat Health Report: #{model}")
  end

end
