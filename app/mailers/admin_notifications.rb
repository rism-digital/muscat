class AdminNotifications < ApplicationMailer

  def notify(message, data = nil)
    
    @message = message
    @data = data
    
    mail(to: RISM::NOTIFICATION_EMAIL,
        name: "Muscat Admin Notificator",
        subject: "A problem occurred")
  end

end
