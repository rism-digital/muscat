class SourceValidationNotifications < ApplicationMailer
	
  def mail_validation(source)
    @errors = []
    @failed = false
    @source_id = source.id
    begin
      validator = MarcValidator.new(source, false)
      validator.validate
      validator.validate_links
      validator.validate_unknown_tags
      @errors = validator.get_errors
    rescue
      @failed = true
    end

    return if @errors.count == 0 && !@failed

    mail(to: RISM::NOTIFICATION_EMAIL,
        name: "Muscat Validation",
        subject: "Source Validation Failure #{@source_id}")
 
  end

end
