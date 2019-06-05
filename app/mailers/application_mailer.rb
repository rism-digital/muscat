class ApplicationMailer < ActionMailer::Base
  default from: "#{RISM::DEFAULT_EMAIL_NAME} <#{RISM::DEFAULT_NOREPLY_EMAIL}>"
  layout 'mailer'
end
