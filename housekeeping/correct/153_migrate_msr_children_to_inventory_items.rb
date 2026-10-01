# frozen_string_literal: true

require "csv"

# Convert the MSR collection Source into an Inventory and create InventoryItems
# from only the child Source IDs listed in the supplied CSV/TSV file.
#
# Expected columns:
#   Muscat, ID, 300$a-to-delete, 773$g, 932$a, 932$4
#
# Run with:
#   rails runner housekeeping/correct/153_migrate_msr_children_to_inventory_items.rb FILE
#
# The script always applies changes. It performs a complete preflight before
# converting the collection or creating any InventoryItems. Output is TSV.

COLLECTION_ID = 300_043_049
PAPER_TRAIL_USER = ENV.fetch(
  "MUSCAT_SCRIPT_USER",
  "Maintenance script MSR inventory migration"
)
REQUIRED_HEADERS = ["ID", "300$a-to-delete", "773$g", "932$a", "932$4"].freeze

MigrationRow = Struct.new(
  :source_id,
  :value_300a,
  :value_773g,
  :identified_source_id,
  :identification_status,
  keyword_init: true
)

class FatalMigrationError < StandardError; end
class RowMigrationError < StandardError; end

def output_tsv(*values)
  puts CSV.generate_line(values, col_sep: "\t")
end

def column_separator(filename)
  header = File.open(filename, "r:bom|utf-8", &:gets).to_s
  ["\t", ",", ";"].max_by { |separator| header.count(separator) }
end

def normalized_hash(row)
  row.to_h.each_with_object({}) do |(header, value), result|
    next if header.nil?

    result[header.delete_prefix("\uFEFF").strip] = value&.strip
  end
end

def read_rows(filename)
  separator = column_separator(filename)
  rows = []
  errors = []
  headers = nil

  CSV.foreach(
    filename,
    headers: true,
    col_sep: separator,
    encoding: "bom|utf-8"
  ).with_index(2) do |csv_row, line_number|
    values = normalized_hash(csv_row)
    headers ||= values.keys
    next if values["ID"].to_s.empty?

    unless values["ID"].match?(/\A\d+\z/)
      errors << "CSV line #{line_number}: invalid Source ID #{values['ID'].inspect}"
      next
    end

    identified_source_id = values["932$a"]
    identification_status = values["932$4"]

    if identified_source_id.present? != identification_status.present?
      errors << "Source #{values['ID']}: incomplete 932 ignored"
      identified_source_id = nil
      identification_status = nil
    end

    if identified_source_id.present? && !identified_source_id.match?(/\A\d+\z/)
      errors << "Source #{values['ID']}: invalid 932$a ignored: #{identified_source_id.inspect}"
      identified_source_id = nil
      identification_status = nil
    end

    rows << MigrationRow.new(
      source_id: values["ID"].to_i,
      value_300a: values["300$a-to-delete"],
      value_773g: values["773$g"],
      identified_source_id: identified_source_id.present? ? identified_source_id.to_i : nil,
      identification_status: identification_status
    )
  end

  missing_headers = REQUIRED_HEADERS - Array(headers)
  unless missing_headers.empty?
    raise FatalMigrationError, "Missing CSV column(s): #{missing_headers.join(', ')}"
  end

  if rows.empty?
    raise FatalMigrationError, "The input contains no migration rows"
  end

  duplicate_ids = rows.group_by(&:source_id).select { |_id, entries| entries.length > 1 }.keys
  unless duplicate_ids.empty?
    errors << "Duplicate CSV Source ID(s) ignored after first occurrence: #{duplicate_ids.join(', ')}"
    rows = rows.uniq(&:source_id)
  end

  [rows, errors]
end

def linked_to_collection?(source, collection_id)
  return true if source.source_id == collection_id

  source.marc["773"].any? do |field|
    field["w"].any? { |subfield| subfield.content.to_i == collection_id }
  end
end

def migrated_from_source?(item, child_source)
  import_note = "Imported from sources/#{child_source.id}"

  ["599", "500"].any? do |tag|
    item.marc[tag].any? do |field|
      field["a"].any? { |subfield| subfield.content == import_note }
    end
  end
end

def already_migrated_item(collection, child_source)
  preferred = InventoryItem.find_by(id: child_source.id, source_id: collection.id)
  return preferred if preferred && migrated_from_source?(preferred, child_source)

  InventoryItem.where(source_id: collection.id).where.not(id: child_source.id).find_each.find do |item|
    migrated_from_source?(item, child_source)
  end
end

def validate_collection!(collection)
  valid_collection_types = [
    MarcSource::RECORD_TYPES[:collection],
    MarcSource::RECORD_TYPES[:inventory]
  ]

  unless valid_collection_types.include?(collection.record_type)
    raise FatalMigrationError,
          "Source #{collection.id} must be a collection or inventory; " \
          "it is #{collection.get_record_type.inspect}"
  end
end

def validate_row!(collection, child, row)
  unless linked_to_collection?(child, collection.id)
    raise RowMigrationError,
          "Source #{child.id} is not a child of collection #{collection.id}"
  end

  if row.value_300a.to_s.empty?
    raise RowMigrationError, "Source #{child.id}: 300$a-to-delete is blank"
  end

  actual_300a = child.marc["300"].flat_map do |field|
    field["a"].map { |subfield| subfield.content.to_s }
  end

  unless actual_300a.include?(row.value_300a)
    raise RowMigrationError,
          "Source #{child.id}: CSV 300$a #{row.value_300a.inspect} " \
          "does not match MARC values #{actual_300a.inspect}"
  end

  if row.value_773g.to_s.empty?
    raise RowMigrationError, "Source #{child.id}: 773$g is blank"
  end

  if row.identified_source_id && !Source.exists?(id: row.identified_source_id)
    raise RowMigrationError,
          "Source #{child.id}: identified Source #{row.identified_source_id} does not exist"
  end

  owner = child.user || collection.user
  unless owner
    raise RowMigrationError,
          "Source #{child.id}: neither the child nor collection has a valid owner"
  end
end

def migration_source_order(collection, rows)
  errors = []
  collection_order = collection.marc["774"].filter_map do |field|
    source_id = field["w"].first&.content
    source_id.to_i if source_id.present?
  end

  migration_ids = rows.map(&:source_id)
  duplicate_ids = collection_order
    .select { |source_id| migration_ids.include?(source_id) }
    .group_by(&:itself)
    .select { |_source_id, occurrences| occurrences.length > 1 }
    .keys

  unless duplicate_ids.empty?
    errors << "Collection #{collection.id} has duplicate 774 links; first occurrence used for: " \
              "#{duplicate_ids.join(', ')}"
  end

  collection_order = collection_order.uniq
  missing_ids = migration_ids - collection_order
  unless missing_ids.empty?
    errors << "CSV Source ID(s) missing from collection #{collection.id} 774 order; " \
              "appended in CSV order: #{missing_ids.join(', ')}"
  end

  ordered_ids = collection_order.select { |source_id| migration_ids.include?(source_id) }
  [ordered_ids + missing_ids, errors]
end

def remove_300_a_and_8(marc)
  marc["300"].dup.each do |field|
    field["a"].dup.each(&:destroy_yourself)
    field["8"].dup.each(&:destroy_yourself)
    field.destroy_yourself if field.children.empty?
  end
end

def remove_all_932(marc)
  marc["932"].dup.each(&:destroy_yourself)
end

def remove_all_852(marc)
  marc["852"].dup.each(&:destroy_yourself)
end

def move_import_note_to_599(marc, source_id)
  import_notes = [
    "Imported from #{source_id}",
    "Imported from sources/#{source_id}"
  ]

  ["500", "599"].each do |tag|
    marc[tag].dup.each do |field|
      field["a"].dup.each do |subfield|
        subfield.destroy_yourself if import_notes.include?(subfield.content)
      end
      field.destroy_yourself if field.children.empty?
    end
  end

  marc.add_tag_with_subfields("599", a: "Imported from sources/#{source_id}")
end

def add_parent_773(marc, collection_id, page_info)
  field = marc["773"].find do |candidate|
    candidate["w"].any? { |subfield| subfield.content.to_i == collection_id }
  end

  field ||= marc.add_tag_with_subfields("773", w: collection_id)
  field["g"].dup.each(&:destroy_yourself)
  field.add_at(MarcNode.new("inventory_item", "g", page_info, nil), 0)
  field.sort_alphabetically
end

def add_identified_source(marc, source_id, status)
  return unless source_id

  marc.add_tag_with_subfields("932", w: source_id, "4": status)
end

def copy_all_source_marc(item, child)
  copied_marc = MarcInventoryItem.new(child.marc_source)
  copied_marc.load_source(false)
  copied_marc.set_id(item.id)
  item.marc = copied_marc
end

def migrate_row(collection, row)
  child = Source.find(row.source_id)
  existing = already_migrated_item(collection, child)
  return [:already_migrated, existing] if existing
  validate_row!(collection, child, row)

  item = nil

  InventoryItem.transaction do
    owner = child.user || collection.user
    preserved_id = child.id unless InventoryItem.exists?(id: child.id)
    item = InventoryItem.new(
      id: preserved_id,
      source: collection,
      user: owner,
      wf_stage: child.wf_stage,
      wf_audit: child.wf_audit
    )

    # Create the InventoryItem and its permanent ID before replacing the
    # scaffolded MARC with the complete child Source MARC. The copied 001 must
    # identify the InventoryItem, particularly when the Source ID is already
    # occupied in the inventory_items table.
    item.save!
    copy_all_source_marc(item, child)
    move_import_note_to_599(item.marc, child.id)

    # These fields are intentionally transformed for the inventory migration.
    remove_300_a_and_8(item.marc)
    remove_all_852(item.marc)
    add_parent_773(item.marc, collection.id, row.value_773g)

    # 932 must only exist on rows where the two spreadsheet columns are
    # populated, so discard any copied 932 before adding the requested link.
    remove_all_932(item.marc)

    # The spreadsheet calls this input 932$a, but its numeric value is the
    # selected Source ID. Muscat stores that master link in 932$w and resolves
    # the human-readable 932$a during import.
    add_identified_source(
      item.marc,
      row.identified_source_id,
      row.identification_status
    )

    item.marc.import(false, owner)
    item.last_user_save = PAPER_TRAIL_USER
    item.paper_trail_event = "Migrate MSR Source #{child.id} to InventoryItem"
    item.save!
  end

  [:created, item]
end

def order_migrated_items!(collection, ordered_source_ids)
  ordered_count = 0
  failures = []

  ordered_source_ids.each_with_index do |source_id, source_order|
    begin
      InventoryItem.transaction do
        child = Source.find(source_id)
        item = already_migrated_item(collection, child)

        unless item
          raise RowMigrationError, "no migrated InventoryItem was found"
        end

        item.update!(source_order: source_order)
        ordered_count += 1
      end
    rescue StandardError => error
      failures << [source_id, error.message]
    end
  end

  [ordered_count, failures]
end

def delete_migrated_sources!(collection, rows)
  deleted_ids = []
  failures = []

  rows.each do |row|
    begin
      Source.transaction do
        child = Source.find(row.source_id)
        item = already_migrated_item(collection, child)

        unless item
          raise RowMigrationError,
                "no migrated InventoryItem was found"
        end

        child.last_user_save = PAPER_TRAIL_USER
        child.paper_trail_event = "Delete after migration to InventoryItem #{item.id}"

        # Source#check_parent prevents deletion while this database parent link
        # remains. If deletion fails, this transaction restores the link.
        child.update_column(:source_id, nil) if child.source_id
        child.destroy!
        deleted_ids << child.id
      end
    rescue StandardError => error
      details = if error.respond_to?(:record) && error.record
        error.record.errors.full_messages.to_sentence.presence
      end
      failures << [row.source_id, details || error.message]
    end
  end

  [deleted_ids, failures]
end

filename = ARGV.shift

unless filename && File.file?(filename) && ARGV.empty?
  warn <<~HELP
    Usage:
      rails runner housekeeping/correct/153_migrate_msr_children_to_inventory_items.rb FILE
  HELP
  exit 1
end

begin
  rows, input_errors = read_rows(filename)
  collection = Source.find_by(id: COLLECTION_ID)
  raise FatalMigrationError, "Collection Source #{COLLECTION_ID} does not exist" unless collection

  validate_collection!(collection)
  ordered_source_ids, order_input_errors = migration_source_order(collection, rows)
  (input_errors + order_input_errors).each { |message| warn "WARNING: #{message}" }

  PaperTrail.request.whodunnit = PAPER_TRAIL_USER

  unless collection.record_type == MarcSource::RECORD_TYPES[:inventory]
    collection.paper_trail_event = "Convert MSR collection to Inventory"
    collection.change_template_to(MarcSource::RECORD_TYPES[:inventory])
    collection.reload

    unless collection.record_type == MarcSource::RECORD_TYPES[:inventory]
      raise FatalMigrationError, "Could not convert Source #{collection.id} to an Inventory"
    end
  end

  counts = Hash.new(0)
  output_tsv(
    "source_id",
    "inventory_item_id",
    "status",
    "773$g",
    "identified_source_id",
    "identification_status",
    "details"
  )

  rows.each do |row|
    begin
      status, item = migrate_row(collection, row)
      label = status == :created ? "CREATED" : "ALREADY MIGRATED"
      counts[label] += 1
      output_tsv(
        row.source_id,
        item.id,
        label,
        row.value_773g,
        row.identified_source_id,
        row.identification_status,
        nil
      )
    rescue StandardError => error
      counts["ERROR"] += 1
      output_tsv(
        row.source_id,
        nil,
        "ERROR",
        row.value_773g,
        row.identified_source_id,
        row.identification_status,
        "#{error.class}: #{error.message}"
      )
    end
  end

  # Preserve the order of the original collection's 774 links in the
  # InventoryItem-specific source_order column before deleting the Sources.
  ordered_count, ordering_failures = order_migrated_items!(collection, ordered_source_ids)

  # Source deletion is deliberately a separate, best-effort final task.
  # A failed deletion is logged and does not undo conversion or ordering.
  deleted_source_ids, deletion_failures = delete_migrated_sources!(collection, rows)

  warn "Inventory Source: #{collection.id}"
  warn counts.sort.map { |status, count| "#{status}: #{count}" }.join(", ")
  warn "ORDERED INVENTORY ITEMS: #{ordered_count}"
  warn "INVENTORY ITEMS NOT ORDERED: #{ordering_failures.length}"
  ordering_failures.each do |source_id, message|
    warn "INVENTORY ITEM NOT ORDERED #{source_id}: #{message}"
  end
  warn "DELETED SOURCES: #{deleted_source_ids.length}"
  warn "SOURCES NOT DELETED: #{deletion_failures.length}"
  deletion_failures.each do |source_id, message|
    warn "SOURCE NOT DELETED #{source_id}: #{message}"
  end
rescue FatalMigrationError, CSV::MalformedCSVError => error
  warn "CANNOT RUN: #{error.message}"
  exit 1
end
