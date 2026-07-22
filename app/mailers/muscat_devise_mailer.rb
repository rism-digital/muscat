class MuscatDeviseMailer < Devise::Mailer
  around_action :force_english_locale

  def invitation_instructions(record, token, opts = {})
    attachments.inline["rism-logo.png"] = File.binread(
      Rails.root.join("public", "images", "logo-large-zr.png")
    )

    super
  end

  private

  def force_english_locale(&block)
    I18n.with_locale(:en, &block)
  end
end
