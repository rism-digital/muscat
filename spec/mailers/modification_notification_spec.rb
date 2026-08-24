require "rails_helper"

RSpec.describe ModificationNotification, type: :mailer do
  describe "#notify" do
    it "renders compact numbered match tables with explicit trigger patterns" do
      user = instance_double(User, name: "Cataloguer", email: "cataloguer@example.org")
      person = Person.new(
        id: 123,
        full_name: "Bach, Johann Sebastian",
        life_dates: "1685–1750",
        created_at: Time.zone.parse("2026-08-20 10:15"),
        updated_at: Time.zone.parse("2026-08-24 11:45")
      )
      results = {
        "person" => {
          "full_name Bach* AND life_dates 1685*" => [person]
        }
      }

      mail = described_class.notify(user, 1, results, "Generated in 2 seconds").message
      body = mail.html_part.body.decoded

      expect(mail.to).to eq(["cataloguer@example.org"])
      expect(mail.subject).to eq("Modification report: 1 match")
      expect(mail.attachments["rism-logo.png"]).to be_inline
      expect(body).to include("Muscat notification")
      expect(body).to include("One notification match was found.")
      expect(body).to include("Jump to a match")
      expect(body).to include('href="#modification-match-1"')
      expect(body).to include('id="modification-match-1"')
      expect(body).to include("1 Person")
      expect(body).to include("Triggered by")
      expect(body).to include("full_name Bach* AND life_dates 1685*")
      expect(body).to include('id="modification-report-index"')
      expect(body).to include('href="#modification-report-index"')
      expect(body).to include("Back to index")
      expect(body).to include("Bach, Johann Sebastian")
      expect(body).to include("2026-08-20 10:15")
      expect(body).to include("2026-08-24 11:45")
      expect(body).to include("Generated in 2 seconds")
    end
  end
end
