class HealthReport < ApplicationMailer

  def notify(model, message, errors, validations, foreign_tag_errors, unknown_tags)
    
    @message = message
    @model = model
    @errors = errors
    @validations = validations
    @foreign_tag_errors = foreign_tag_errors
		@unknown_tags = unknown_tags
    
    #path = Rails.root.join('public', "validation.html")

    ## Bush fix!!
    #File.open(path, "w") { |file| file.write(render(partial: "health_report/validation.html.erb")) }

    attachments["validation.html"] = render(partial: "health_report/validation.html.erb")

    mail(to: RISM::NOTIFICATION_EMAILS,
      from: "#{RISM::DEFAULT_EMAIL_NAME} Periodic Validation Bot <#{RISM::DEFAULT_NOREPLY_EMAIL}>",
      subject: "Muscat Health Report: #{model}")
  end

end
