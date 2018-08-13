class ModificationNotification < ApplicationMailer

  def notify(matches, source, user)
    
    @matches = matches
    @source = source
    @user = user
    
    return if !@user || !@user.email

    mail(to: @user.email,
        name: "Muscat Modification Notificator",
        subject: "Source #{@source.id} was modified")
  end

end
