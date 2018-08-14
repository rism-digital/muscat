class ModificationNotification < ApplicationMailer

  def notify(user, results = {})
    
    @results = results
    @user = user
    
    return if !@user || !@user.email

    mail(to: @user.email,
        name: "Muscat Modification Notificator",
        subject: "Source modification report")
  end

end
