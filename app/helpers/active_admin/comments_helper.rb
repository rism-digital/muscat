# frozen_string_literal: true

module ActiveAdmin::CommentsHelper
  COMMENT_BODY_ALLOWED_TAGS = %w[p br strong em u s ul ol li blockquote code pre span a].freeze
  COMMENT_BODY_ALLOWED_ATTRIBUTES = %w[class style href target rel data-mention-id data-mention-label].freeze

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
          comment.author ? auto_link(comment.author) : I18n.t("active_admin.comments.author_missing")
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

      context.div sanitize(comment.body.to_s, tags: COMMENT_BODY_ALLOWED_TAGS, attributes: COMMENT_BODY_ALLOWED_ATTRIBUTES), class: "active_admin_comment_body"
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
end
