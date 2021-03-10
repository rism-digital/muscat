class PublicationValidationNotifications < ApplicationMailer
	
  def mail_validation(publication)
    @errors = []
    @failed = nil
    @publication_id = publication.id
    begin
      # Note: we need to load MARC again from an unloaded state
      validator = MarcValidator.new(Publication.find(@publication_id))
      validator.validate_tags
      @errors = validator.get_errors
    rescue Exception => e
      @failed = e
    end

    return if @errors.count == 0 && !@failed

    #mail(to: RISM::NOTIFICATION_EMAILS,
    #    name: "Muscat Validation",
    #    subject: "Source Validation Failure #{@source_id}")
 
  end

end
