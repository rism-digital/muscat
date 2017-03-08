class SourceValidationNotifications < ApplicationMailer
	
  def mail_validation(source)
    @errors = []
    @failed = nil
    @source_id = source.id
    begin
      # Note: we need to load MARC again from an unloaded state
      validator = MarcValidator.new(Source.find(@source_id), false)
      validator.validate
      validator.validate_links
      validator.validate_unknown_tags
      @errors = validator.get_errors
    rescue Exception => e
      @failed = e
    end

    return if @errors.count == 0 && !@failed

    mail(to: RISM::NOTIFICATION_EMAIL,
        name: "Muscat Validation",
        subject: "Source Validation Failure #{@source_id}")
 
  end

end
