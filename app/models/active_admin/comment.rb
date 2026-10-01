# frozen_string_literal: true

require "json"

class ActiveAdmin::Comment
  before_validation :normalize_rich_text_payload

  def body_json_document
    case body_json
    when String
      JSON.parse(body_json)
    else
      body_json
    end
  rescue JSON::ParserError
    nil
  end

  def mentioned_user_ids_from_json
    extract_mentioned_user_ids(body_json_document).uniq
  end

  def body_from_json
    extract_plain_text(body_json_document).strip
  end

  private

  def normalize_rich_text_payload
    document = body_json_document
    return if document.blank?

    self.body_json = document
    self.body = body_from_json
    self.mentioned_user_ids = mentioned_user_ids_from_json
  end

  def extract_plain_text(node)
    case node
    when Array
      node.map { |child| extract_plain_text(child) }.join
    when Hash
      case node["type"]
      when "doc"
        Array(node["content"]).map { |child| extract_plain_text(child) }.join("\n\n")
      when "paragraph", "heading", "blockquote"
        Array(node["content"]).map { |child| extract_plain_text(child) }.join
      when "bulletList", "orderedList"
        Array(node["content"]).map { |child| extract_plain_text(child) }.join("\n")
      when "listItem"
        Array(node["content"]).map { |child| extract_plain_text(child) }.join
      when "hardBreak"
        "\n"
      when "mention"
        label = node.dig("attrs", "label").presence || node.dig("attrs", "id").to_s
        "@#{label}"
      when "text"
        node["text"].to_s
      else
        Array(node["content"]).map { |child| extract_plain_text(child) }.join
      end
    else
      ""
    end
  end

  def extract_mentioned_user_ids(node)
    case node
    when Array
      node.flat_map { |child| extract_mentioned_user_ids(child) }
    when Hash
      ids = []
      ids << normalized_user_id(node.dig("attrs", "id")) if node["type"] == "mention"
      ids.concat(Array(node["content"]).flat_map { |child| extract_mentioned_user_ids(child) })
      ids.compact
    else
      []
    end
  end

  def normalized_user_id(value)
    Integer(value)
  rescue ArgumentError, TypeError
    nil
  end
end
