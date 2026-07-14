# frozen_string_literal: true

module ActiveAdmin::CommentsHelper
  def active_admin_muscat_comments(context, item)
    return unless authorized?(ActiveAdmin::Auth::READ, ActiveAdmin::Comment)

    comments = ActiveAdmin::Comment.find_for_resource_in_namespace(item, active_admin_namespace.name)
    comments = comments.includes(:author)
    comments = active_admin_authorization.scope_collection(comments) if respond_to?(:active_admin_authorization)
    comments = comments.page(params[:comments_page])

    context.panel I18n.t("active_admin.comments.title_content", count: comments.total_count), class: "comments" do
      if comments.any?
        comments.each do |comment|
          active_admin_muscat_build_comment(context, comment)
        end
        context.div page_entries_info(comments).html_safe, class: "pagination_information"
      else
        context.span I18n.t("active_admin.comments.no_comments_yet"), class: "empty"
      end

      context.text_node paginate(comments, param_name: :comments_page)

      if authorized?(ActiveAdmin::Auth::NEW, ActiveAdmin::Comment)
        context.text_node render(partial: "shared/active_admin_comment_form", locals: {
          resource: item,
          comment_form_url: active_admin_muscat_comment_form_url,
          users_url: "/admin/users/list"
        })
      end
    end
  end

  def active_admin_muscat_build_comment(context, comment)
    context.div for: comment do
      context.div class: "active_admin_comment_meta" do
        context.h4 class: "active_admin_comment_author" do
          if comment.author
            parts = []
            badge = rism_staff_comment_badge(comment.author)
            parts << badge if badge.present?
            parts << auto_link(comment.author)
            context.text_node safe_join(parts, " ")
          else
            I18n.t("active_admin.comments.author_missing")
          end
        end
        context.span pretty_format(comment.created_at)
        if authorized?(ActiveAdmin::Auth::DESTROY, comment)
          context.text_node link_to(
            I18n.t("active_admin.comments.delete"),
            active_admin_muscat_comment_url(comment.id),
            method: :delete,
            data: { confirm: I18n.t("active_admin.comments.delete_confirmation") }
          )
        end
      end

      context.div render_active_admin_comment_body(comment), class: "active_admin_comment_body"
    end
  end

  def active_admin_muscat_comment_url(id)
    parts = []
    parts << active_admin_namespace.name unless active_admin_namespace.root?
    parts << active_admin_namespace.comments_registration_name.underscore
    parts << "path"
    send parts.join("_"), id
  end

  def active_admin_muscat_comment_form_url
    parts = []
    parts << active_admin_namespace.name unless active_admin_namespace.root?
    parts << active_admin_namespace.comments_registration_name.underscore.pluralize
    parts << "path"
    send parts.join("_")
  end

  def render_active_admin_comment_body(comment_or_body)
    if comment_or_body.respond_to?(:body_json_document)
      document = comment_or_body.body_json_document
      return render_active_admin_comment_document(document) if document.present?

      return render_legacy_active_admin_comment_body(comment_or_body.body)
    end

    render_legacy_active_admin_comment_body(comment_or_body)
  end

  def render_active_admin_comment_document(document)
    return "".html_safe if document.blank?

    if document.is_a?(Array)
      return safe_join(document.map { |node| render_active_admin_comment_node(node) })
    end

    case document["type"]
    when "doc"
      safe_join(Array(document["content"]).map { |node| render_active_admin_comment_node(node) })
    else
      render_active_admin_comment_node(document)
    end
  end

  def render_active_admin_comment_node(node)
    return "".html_safe unless node.is_a?(Hash)

    case node["type"]
    when "paragraph"
      content_tag(:p, render_active_admin_comment_inline_content(node["content"]))
    when "heading"
      level = node.dig("attrs", "level").to_i
      level = 1 if level < 1
      level = 6 if level > 6
      content_tag("h#{level}", render_active_admin_comment_inline_content(node["content"]))
    when "blockquote"
      content_tag(:blockquote, safe_join(Array(node["content"]).map { |child| render_active_admin_comment_node(child) }))
    when "bulletList"
      content_tag(:ul, safe_join(Array(node["content"]).map { |child| content_tag(:li, render_active_admin_comment_node(child)) }))
    when "orderedList"
      content_tag(:ol, safe_join(Array(node["content"]).map { |child| content_tag(:li, render_active_admin_comment_node(child)) }))
    when "listItem"
      safe_join(Array(node["content"]).map { |child| render_active_admin_comment_node(child) })
    when "hardBreak"
      tag.br
    else
      render_active_admin_comment_inline_content(node["content"])
    end
  end

  def render_active_admin_comment_inline_content(content)
    safe_join(Array(content).map do |node|
      case node["type"]
      when "text"
        render_active_admin_comment_text_node(node)
      when "hardBreak"
        tag.br
      when "mention"
        render_active_admin_comment_mention_node(node)
      else
        render_active_admin_comment_inline_content(node["content"])
      end
    end)
  end

  def render_active_admin_comment_text_node(node)
    html = h(node["text"].to_s)

    Array(node["marks"]).reduce(html) do |acc, mark|
      render_active_admin_comment_mark(acc, mark)
    end
  end

  def render_active_admin_comment_mark(html, mark)
    case mark["type"]
    when "bold"
      content_tag(:strong, html)
    when "italic"
      content_tag(:em, html)
    when "strike"
      content_tag(:s, html)
    when "code"
      content_tag(:code, html)
    when "link"
      href = mark.dig("attrs", "href").to_s
      return html unless href.match?(/\A(?:https?:\/\/|mailto:|\/)/)

      content_tag(:a, html, href: href, rel: "nofollow noopener noreferrer", target: "_blank")
    else
      html
    end
  end

  def render_active_admin_comment_mention_node(node)
    label = node.dig("attrs", "label").presence || node.dig("attrs", "id").to_s
    content_tag(
      :span,
      "@#{h(label)}".html_safe,
      class: "comment-mention mention-editor__mention",
      data: {
        mention_id: node.dig("attrs", "id"),
        mention_label: label,
      }
    )
  end

  def render_legacy_active_admin_comment_body(body)
    normalized_body = body.to_s.gsub("\r\n", "\n").gsub("\r", "\n")
    paragraphs = normalized_body.split(/\n{2,}/).map(&:strip).reject(&:blank?)
    paragraphs = [""] if paragraphs.empty?

    safe_join(
      paragraphs.map do |paragraph|
        content_tag(:p, Anchored::Linker.auto_link(h(paragraph)).html_safe)
      end
    )
  end

  def rism_staff_comment_badge(author)
    return unless author.respond_to?(:has_role?)
    return unless author.has_role?(:admin) || author.has_role?(:editor)

    content_tag(:span, "RISM Staff", class: "status_tag warning")
  end
end
