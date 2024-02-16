=begin
class MarkdownTemplateHandler
    def call(md, template)
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  
      "#{markdown.render(template.source).inspect}.html_safe;"
    end
  end

ActionView::Template.register_template_handler(:md, MarkdownTemplateHandler.new)
=end


class MarkdownHandler
  def call(template, source)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

    "#{markdown.render(source).inspect}.html_safe"
  end
end


ActionView::Template.register_template_handler :md, MarkdownHandler.new
