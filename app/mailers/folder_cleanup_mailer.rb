class FolderCleanupMailer < ApplicationMailer

    def notify(email, folders)

      @folders = folders

      @dates = {
        delete_now: Date.today,
        tomorrow: Date.today + 1.days,
        one_week: Date.today + 7.days,
        two_weeks: Date.today + 14.days,
        one_month: Date.today + 1.month
      }

      mail(to: email,
          from: "#{RISM::DEFAULT_EMAIL_NAME} Folder Notificator <#{RISM::DEFAULT_NOREPLY_EMAIL}>",
          subject: I18n.t(:"folders.expiring_folders"))
    end
  
  end
  