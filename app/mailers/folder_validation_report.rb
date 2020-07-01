class FolderValidationReport < ApplicationMailer

    def notify(model, message, errors, validations, foreign_tag_errors, unknown_tags, user)
      
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
  
      mail(to: user.email,
        from: "#{RISM::DEFAULT_EMAIL_NAME} Folder Validator <#{RISM::DEFAULT_NOREPLY_EMAIL}>",
        subject: "Folder validation: #{model}")
    end
  
  end
  