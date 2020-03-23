class ModificationNotification < ApplicationMailer

  def notify(user, results = {}, results_by_criteria = {})
    
    @results = results
    @results_by_criteria = results_by_criteria
    @user = user
    
    return if !@user || !@user.email

    if @results.count > 1
      subject = "Source modification report: #{@results.count} records"
    else
      s = results_by_criteria.values.first[0]

      composer = !s.composer.empty? ? s.composer : "n.a."
      title = !s.std_title.empty? ? s.std_title : "none"
      subject = "Source #{composer}: #{title} (#{s.id}) was modified"
    end

    mail(to: @user.email,
        from: "#{RISM::DEFAULT_EMAIL_NAME} Modification Notificator <#{RISM::DEFAULT_NOREPLY_EMAIL}>",
        subject: subject)
  end

end
