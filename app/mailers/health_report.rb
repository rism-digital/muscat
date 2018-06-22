class HealthReport < ApplicationMailer

  def notify(model, message, errors, validations)
    
    @message = message
		@model = model
		@errors = errors
		@validations = validations
    
		path = Rails.root.join('public', "validation.html")

		File.open(path, "w") { |file| file.write(render(partial: "health_report/validation.html.erb")) }
		
    mail(to: RISM::NOTIFICATION_EMAIL,
        name: "Muscat Admin Notificator",
        subject: "Muscat Health Report: #{model}")
  end

end
