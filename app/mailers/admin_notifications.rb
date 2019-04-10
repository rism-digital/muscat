class AdminNotifications < ApplicationMailer

  def notify(message, data = nil)
    
    @message = message
    @data = data
    
    mail(to: RISM::NOTIFICATION_EMAIL,
        from: "#{RISM::DEFAULT_EMAIL_NAME} Admin Notificator Bot <#{RISM::DEFAULT_NOREPLY_EMAIL}>"
        subject: "A problem occurred")
  end

end
