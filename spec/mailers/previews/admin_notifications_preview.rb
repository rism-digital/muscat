# Preview all emails at http://localhost:3000/rails/mailers/admin_notifications
class AdminNotificationsPreview < ActionMailer::Preview
  def notify
    AdminNotifications.notify("test", ["Test data", Source.first])
  end
end
