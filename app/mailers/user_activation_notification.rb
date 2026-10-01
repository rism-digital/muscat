class UserActivationNotification < ApplicationMailer
  SIGLA_LIMIT = 100
  around_action :force_english_locale

  def notify(user)
    attachments.inline["rism-logo.png"] = File.binread(
      Rails.root.join("public", "images", "logo-large-zr.png")
    )

    @user = user
    @workgroups = user.workgroups.sort_by(&:name).map do |workgroup|
      sigla = workgroup.institutions.map(&:siglum).compact_blank.uniq.sort

      {
        name: workgroup.name,
        sigla: sigla.first(SIGLA_LIMIT),
        omitted_sigla_count: [sigla.size - SIGLA_LIMIT, 0].max
      }
    end

    mail(
      to: Array(RISM::USER_ACTIVATION_NOTIFICATION_EMAILS).compact_blank,
      subject: I18n.t("user_activation_notification.subject", username: user.username)
    )
  end

  private

  def force_english_locale(&block)
    I18n.with_locale(:en, &block)
  end
end
