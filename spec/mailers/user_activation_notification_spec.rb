require "rails_helper"

RSpec.describe UserActivationNotification, type: :mailer do
  describe "#notify" do
    it "includes the activated user and limits each workgroup to 100 sigla" do
      institutions = 102.times.map do |index|
        instance_double(Institution, siglum: format("CH-%03d", index))
      end
      workgroup = instance_double(Workgroup, name: "Switzerland", institutions: institutions)
      user = instance_double(
        User,
        username: "cataloguer",
        name: "New Cataloguer",
        email: "cataloguer@example.org",
        workgroups: [workgroup]
      )

      mail = described_class.notify(user)

      expect(mail.to).to eq(RISM::USER_ACTIVATION_NOTIFICATION_EMAILS)
      expect(mail.subject).to eq("[Muscat] User activated: cataloguer")
      expect(mail.body.encoded).to include("New Cataloguer")
      expect(mail.body.encoded).to include("cataloguer@example.org")
      expect(mail.body.encoded).to include("Switzerland")
      expect(mail.body.encoded).to include("CH-099")
      expect(mail.body.encoded).not_to include("CH-100")
      expect(mail.body.encoded).to include("2 more")
    end
  end
end
