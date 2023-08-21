class HealthReport < ApplicationMailer

  def get_zip_data(file_path, file_name)
    
    zip_file = Tempfile.new("#{file_name}.zip")
  
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
    
    @render_partial = false

    # Create a file name with the model and the date, append to the date seconds + nanoseconds
    # to create an unique file name
    time = Time.now.strftime('%Y-%m-%d-%s%4N')
    model_file = @model.is_a?(Source) ? "validation" : "#{@model.to_s.underscore.downcase}_validation"
    file_name = "#{model_file}-#{time}"

    path = Rails.root.join('tmp', "#{file_name}.html")

    # This is not the most efficent way but hey this runs once a week
    # Generate the error report and see if it is bigger than 100k
    # if so, compress the file and send a zip attached
    # else just render it in the email body
    File.open(path, "w") { |file| file.write(render(partial: "health_report/validation.html.erb")) }

    if File.size(path) >= 102400
      attachments["#{file_name}.zip"] = get_zip_data(path, file_name)
    else
      @render_partial = true
    end

    # clean up!
    File.unlink(path)

    #attachments["validation.html"] = render(partial: "health_report/validation.html.erb")
    
    mail(to: RISM::NOTIFICATION_EMAILS,
      from: "#{RISM::DEFAULT_EMAIL_NAME} Periodic Validation Bot <#{RISM::DEFAULT_NOREPLY_EMAIL}>",
      subject: "Muscat Health Report: #{model}")
  end

end
