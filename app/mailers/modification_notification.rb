class ModificationNotification < ApplicationMailer

  def notify(user, total_results = 0, results = {}, time_msg = "")
    
    @total_results = total_results
    @results = results
    @user = user
    @time_msg = time_msg
    
    return if !@user || !@user.email

    if total_results > 1
      subject = "Modification report: #{total_results} records"
    else
      subject = "Modification report: 1 record"
    end

    mail(to: @user.email,
        from: "#{RISM::DEFAULT_EMAIL_NAME} Modification Notificator <#{RISM::DEFAULT_NOREPLY_EMAIL}>",
        subject: subject)
  end

end
