require "rails_helper"
require "tempfile"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#render_digital_object_markdown" do
    it "renders Markdown and removes unsafe HTML and links" do
      Tempfile.create(["digital-object", ".md"]) do |file|
        file.write(<<~MARKDOWN)
          # Heading

          A **safe** paragraph.

          <script>alert("unsafe")</script>

          [unsafe link](javascript:alert("unsafe"))
        MARKDOWN
        file.flush

        attachment = instance_double(Paperclip::Attachment, path: file.path)
        digital_object = instance_double(DigitalObject, markdown?: true, attachment: attachment)
        rendered = helper.render_digital_object_markdown(digital_object).to_s

        expect(rendered).to include("<h1>Heading</h1>")
        expect(rendered).to include("<strong>safe</strong>")
        expect(rendered).not_to include("<script")
        expect(rendered).not_to include('href="javascript:')
      end
    end
  end
end
