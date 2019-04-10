class ModificationNotification < ApplicationMailer

  def notify(user, results = {})
    
    @results = results
    @user = user
    @sources
    
    @sources = @results.collect {|id, mods| Source.find(id)}

    return if !@user || !@user.email

    subject = @results.count > 1 ? "Source modification report: #{@results.count} records" : "Source #{@results.first[0]} was modified"

    mail(to: @user.email,
        from: "#{RISM::DEFAULT_EMAIL_NAME} Modification Notificator <#{RISM::DEFAULT_NOREPLY_EMAIL}>",
        subject: subject)
  end

end
