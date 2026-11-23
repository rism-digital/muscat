# Run with:
#   bundle exec rails runner housekeeping/psmd/ordered_missing_marc_tags.rb [OUTPUT.ods]
#
# With no output argument, the report is written beside this script. It lists
# PSMD MARC subfield values whose tag code does not occur in the current Muscat
# record. Dynamic subfield columns are ordered by first appearance in PSMD MARC.

require "fileutils"
require "rodf"
require "set"
require_relative "legacy_file"

module OrderedMissingMarcTags
  extend self

  FOLDER_ID = 1855
  DEFAULT_OUTPUT = File.join(__dir__, "missing_marc_tags_folder_1855.ods")
  SKIPPED_CONTROL_TAG = /\A00[0-9]\z/.freeze
  SKIPPED_TAGS = %w[033 040 508 600 852].freeze
  MANUSCRIPT_EXT_ID = %r{manuscripts/(\d+)}i.freeze

  RECORD_HEADERS = [
    "Muscat source ID",
    "PSMD manuscript ext_id",
    "PSMD manuscript ID"
  ].freeze

  ORDERED_FIELD_HEADERS = RECORD_HEADERS + [
    "PSMD field position",
    "Tag",
    "PSMD MARC field"
  ].freeze

  STATUS_HEADERS = [
    "Muscat source ID",
    "PSMD manuscript ext_id",
    "PSMD manuscript ID",
    "Status",
    "Missing tag count"
  ].freeze

  def run
    output_path = ARGV.shift || DEFAULT_OUTPUT
    abort "Unexpected arguments: #{ARGV.join(' ')}" unless ARGV.empty?

    folder = Folder.find(FOLDER_ID)
    abort "Folder #{FOLDER_ID} is #{folder.folder_type}, expected Source." unless folder.folder_type == "Source"

    legacy = LegacyFile.new(File.join(__dir__, "psmd.yml"))
    counts = Hash.new(0)
    report_rows = []
    ordered_field_rows = []
    status_rows = []
    value_columns = []
    value_columns_seen = Set.new

    sources_in_folder(folder).each do |source|
      manuscript_ext_ids = manuscript_ext_ids_from(source)

      if manuscript_ext_ids.empty?
        status_rows << [source.id, "", "", "NO PSMD MANUSCRIPT EXT_ID IN 599", 0]
        counts[:sources_without_ext_id] += 1
        next
      end

      current_tags = source.marc.all_tags(false).map { |field| field.tag.to_s }.to_set

      manuscript_ext_ids.each do |ext_id|
        manuscript = legacy.find(:manuscripts, ext_id, :ext_id)
        unless manuscript
          status_rows << [source.id, ext_id, "", "PSMD MANUSCRIPT NOT FOUND", 0]
          counts[:manuscripts_not_found] += 1
          next
        end

        legacy_marc = MarcGndWork.new(manuscript["source"])
        legacy_fields = legacy_marc.all_tags(false)
        if legacy_fields.empty?
          status_rows << [source.id, ext_id, manuscript["id"], "PSMD MARC EMPTY", 0]
          counts[:empty_legacy_marc] += 1
          next
        end

        values_by_column = Hash.new { |values, column| values[column] = [] }
        missing_fields = legacy_fields.each_with_index.filter_map do |field, index|
          tag = field.tag.to_s
          next if tag.match?(SKIPPED_CONTROL_TAG) || SKIPPED_TAGS.include?(tag) || current_tags.include?(tag)

          field.children.each do |subfield|
            column = "#{tag}$#{subfield.tag}"
            unless value_columns_seen.include?(column)
              value_columns_seen << column
              value_columns << column
            end
            values_by_column[column] << subfield.content.to_s
          end

          ordered_field_rows << [
            source.id,
            ext_id,
            manuscript["id"],
            index + 1,
            tag,
            field.to_marc.strip
          ]
          field
        end

        status = missing_fields.empty? ? "NO MISSING TAG CODES" : "MISSING TAG CODES"
        status_rows << [source.id, ext_id, manuscript["id"], status, missing_fields.length]
        report_rows << [source.id, ext_id, manuscript["id"], values_by_column.transform_values { |values| values.join(" | ") }]
        counts[missing_fields.empty? ? :no_missing_tags : :pairs_with_missing_tags] += 1
        counts[:missing_fields] += missing_fields.length
      end
    end

    spreadsheet = RODF::Spreadsheet.new
    values_table = add_sheet(spreadsheet, "Missing tag values", RECORD_HEADERS + value_columns)
    ordered_fields_table = add_sheet(spreadsheet, "Ordered fields", ORDERED_FIELD_HEADERS)
    statuses_table = add_sheet(spreadsheet, "Record status", STATUS_HEADERS)

    report_rows.each do |source_id, ext_id, manuscript_id, values|
      write_row(values_table, source_id, ext_id, manuscript_id, *value_columns.map { |column| values[column] || "" })
    end
    ordered_field_rows.each { |row| write_row(ordered_fields_table, *row) }
    status_rows.each { |row| write_row(statuses_table, *row) }

    FileUtils.mkdir_p(File.dirname(File.expand_path(output_path)))
    spreadsheet.write_to(output_path)
    warn "Wrote #{output_path} (#{counts[:missing_fields]} missing fields across #{counts[:pairs_with_missing_tags]} PSMD manuscript/source pairs; #{value_columns.length} subfield columns)"
  end

  private

  def add_sheet(spreadsheet, name, headers)
    table = spreadsheet.table(name)
    write_row(table, *headers)
    table
  end

  def write_row(table, *values)
    row = table.row
    values.each { |value| row.cell(value.to_s) }
  end

  def sources_in_folder(folder)
    folder.folder_items
      .where(item_type: "Source")
      .order(:id)
      .includes(:item)
      .map(&:item)
      .compact
  end

  def manuscript_ext_ids_from(source)
    source.marc.all_tags(false)
      .select { |field| field.tag.to_s == "599" }
      .flat_map do |field|
        field["a"].filter_map do |subfield|
          match = subfield.content.to_s.match(MANUSCRIPT_EXT_ID)
          match && match[1]
        end
      end
      .uniq
  end
end

OrderedMissingMarcTags.run
