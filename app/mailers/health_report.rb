class HealthReport < ApplicationMailer

  def get_zip_data(file_path)
    zip_file = Tempfile.new("validation.zip")
  
    Zip::File.open(zip_file.path, Zip::File::CREATE) do |zipfile|
      zipfile.add(File.basename(file_path), file_path)
    end
  
   zip_data = File.read(zip_file.path)
  
   zip_file.close
   zip_file.unlink
   zip_data
  end
  

  def notify(model, message, errors, validations, foreign_tag_errors, unknown_tags)
    
    @message = message
    @model = model
    @errors = errors
    @validations = validations
    @foreign_tag_errors = foreign_tag_errors
		@unknown_tags = unknown_tags
    
    path = Rails.root.join('tmp', "validation.html")

    ## Bush fix!!
    File.open(path, "w") { |file| file.write(render(partial: "health_report/validation.html.erb")) }

    #attachments["validation.html"] = render(partial: "health_report/validation.html.erb")
    attachments["validation.zip"] = get_zip_data(path)

    mail(to: RISM::NOTIFICATION_EMAILS,
      from: "#{RISM::DEFAULT_EMAIL_NAME} Periodic Validation Bot <#{RISM::DEFAULT_NOREPLY_EMAIL}>",
      subject: "Muscat Health Report: #{model}")
  end

end
