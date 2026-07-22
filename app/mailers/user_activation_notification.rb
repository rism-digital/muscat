class UserActivationNotification < ApplicationMailer
  SIGLA_LIMIT = 100

  def notify(user)
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
      subject: "[Muscat] User activated: #{user.username}"
    )
  end
end
