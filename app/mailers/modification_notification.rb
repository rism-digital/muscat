class ModificationNotification < ApplicationMailer
  around_action :force_english_locale

  def notify(user, total_results = 0, results = {}, time_msg = "")
    @total_results = total_results
    @results = results
    @user = user
    @time_msg = time_msg

    return unless @user&.email

    attachments.inline["rism-logo.png"] = File.binread(
      Rails.root.join("public", "images", "logo-large-zr.png")
    )

    subject = I18n.t("modification_notification.subject", count: total_results)

    mail(
      to: @user.email,
      from: "#{RISM::DEFAULT_EMAIL_NAME} Modification Notificator <#{RISM::DEFAULT_NOREPLY_EMAIL}>",
      subject: subject
    )
  end

  private

  def force_english_locale(&block)
    I18n.with_locale(:en, &block)
  end
end
