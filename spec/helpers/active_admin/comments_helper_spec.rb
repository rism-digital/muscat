require "rails_helper"

RSpec.describe ActiveAdmin::CommentsHelper, type: :helper do
  describe "#render_active_admin_comment_body" do
    it "renders rich body_json documents" do
      comment = ActiveAdmin::Comment.new(
        body_json: {
          "type" => "doc",
          "content" => [
            {
              "type" => "paragraph",
              "content" => [
                { "type" => "text", "text" => "Hello " },
                { "type" => "text", "text" => "&#128507; " },
                { "type" => "text", "text" => "world", "marks" => [{ "type" => "bold" }] },
                { "type" => "hardBreak" },
                { "type" => "mention", "attrs" => { "id" => "7", "label" => "Jane" } }
              ]
            },
            {
              "type" => "paragraph",
              "content" => [
                {
                  "type" => "text",
                  "text" => "Example",
                  "marks" => [{ "type" => "link", "attrs" => { "href" => "https://example.com" } }]
                }
              ]
            }
          ]
        }
      )

      rendered = helper.render_active_admin_comment_body(comment).to_s

      expect(rendered).to include("<p>Hello 🌍 <strong>world</strong><br>@Jane</p>")
      expect(rendered).to include(%(<p><a href="https://example.com" rel="nofollow noopener noreferrer" target="_blank">Example</a></p>))
    end

    it "falls back to legacy body rendering when body_json is absent" do
      rendered = helper.render_active_admin_comment_body("Line one\n\nLine two https://example.com &#128507;").to_s

      expect(rendered).to include("<p>Line one</p>")
      expect(rendered).to include(%(<a href="https://example.com">https://example.com</a>))
      expect(rendered).to include("🌍")
    end
  end
end
