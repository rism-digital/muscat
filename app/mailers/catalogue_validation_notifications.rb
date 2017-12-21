class CatalogueValidationNotifications < ApplicationMailer
	
  def mail_validation(catalogue)
    @errors = []
    @failed = nil
    @catalogue_id = catalogue.id
    begin
      # Note: we need to load MARC again from an unloaded state
      validator = MarcValidator.new(Catalogue.find(@catalogue_id), false)
      validator.validate
      @errors = validator.get_errors
    rescue Exception => e
      @failed = e
    end

    return if @errors.count == 0 && !@failed

    #mail(to: RISM::NOTIFICATION_EMAIL,
    #    name: "Muscat Validation",
    #    subject: "Source Validation Failure #{@source_id}")
 
  end

end
