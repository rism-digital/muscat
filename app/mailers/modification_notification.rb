class ModificationNotification < ApplicationMailer

  def notify(user, results = {}, results_by_criteria = {})
    
    @results = results
    @results_by_criteria = results_by_criteria
    @user = user
    
    return if !@user || !@user.email

    subject = @results.count > 1 ? "Source modification report: #{@results.count} records" : "Source #{@results.first[0]} was modified"

    mail(to: @user.email,
        from: "#{RISM::DEFAULT_EMAIL_NAME} Modification Notificator <#{RISM::DEFAULT_NOREPLY_EMAIL}>",
        subject: subject)
  end

end
