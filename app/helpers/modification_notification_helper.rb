# app/helpers/modification_notification_helper.rb
module ModificationNotificationHelper
  ITEM_CONFIG = {
    "Source" => {
      fields: lambda do |item|
        composer = item.composer.present? ? item.composer : "n.a."
        title    = item.std_title.present? ? item.std_title : "none"
        record   = I18n.t("record_types_codes.#{item.record_type || ''}")

        safe_join([
          "(#{record})",
          content_tag(:b, "#{composer}:"),
          content_tag(:i, title)
        ], " ")
      end
    },

    "Institution" => {
      fields: ->(item) { join_present(item.siglum, item.name) }
    },

    "Person" => {
      fields: ->(item) { join_present(item.full_name, item.life_dates) }
    },

    "Holding" => {
      fields: ->(item) { join_present(item.lib_siglum, "part of: #{item.source_id}") }
    },

    "Work" => {
      fields: ->(item) { h(item.title) }
    },

    "InventoryItem" => {
      fields: ->(item) { join_present(item.try(:title), item.try(:composer), "part of: #{item.source_id} (#{item.source.std_title})") }
    },

    "LiturgicalFeast" => {
      fields: ->(item) { join_present(item.try(:name)) }
    },

    "Place" => {
      fields: ->(item) { join_present(item.try(:name), item.try(:country), item.try(:district)) }
    },

    "Publication" => {
      fields: ->(item) { join_present(item.try(:short_name), item.try(:author), item.try(:title), item.try(:place), item.try(:date)) }
    },

    "StandardTerm" => {
      fields: ->(item) { join_present(item.try(:term)) }
    },

    "StandardTitle" => {
      fields: ->(item) { join_present(item.try(:title)) }
    },

    "WorkNode" => {
      fields: ->(item) { join_present(item.try(:title)) }
    }
  }.freeze

  def render_modification_item(item)
    config = ITEM_CONFIG[item.class.name]

    unless config
      return "#{h(item.inspect)} [created: #{item.created_at}, modified: #{item.updated_at}]"
    end

    details = instance_exec(item, &config[:fields])

    safe_join([
      link_to(item.id, [:admin, item]),
      ", ",
      details,
      " [created: #{item.created_at}, modified: #{item.updated_at}]"
    ])
  end

  #def modification_report_groups(results)
  #  results.to_a
  #end

  private

  def join_present(*parts)
    parts = parts.compact_blank.map { |part| h(part) }
    safe_join(parts, ", ")
  end
end