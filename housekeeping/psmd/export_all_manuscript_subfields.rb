# Export all PSMD manuscripts to a wide ODS table, with one column per MARC
# tag/subfield pair (for example, 700$a). Control fields without subfields use
# their tag as the column name. Repeated values are joined in MARC order.
#
# Run with:
#   bundle exec rails runner housekeeping/psmd/export_all_manuscript_subfields.rb [OUTPUT.ods]

require "fileutils"
require "rodf"
require "set"
require_relative "legacy_file"

module ExportAllManuscriptSubfields
  extend self

  DEFAULT_OUTPUT = File.join(__dir__, "all_psmd_manuscripts_marc_subfields.ods")
  RECORD_HEADERS = ["PSMD manuscript ID", "PSMD manuscript ext_id"].freeze

  def run
    output_path = ARGV.shift || DEFAULT_OUTPUT
    abort "Unexpected arguments: #{ARGV.join(' ')}" unless ARGV.empty?

    legacy = LegacyFile.new(File.join(__dir__, "psmd.yml"))
    manuscripts = legacy.table(:manuscripts)
    columns = []
    columns_seen = Set.new
    rows = []
    statuses = []

    manuscripts.each do |manuscript|
      values_by_column = Hash.new { |values, column| values[column] = [] }
      fields = MarcGndWork.new(manuscript["source"]).all_tags(false)

      fields.each do |field|
        tag = field.tag.to_s

        if field.children.empty?
          column = tag
          unless columns_seen.include?(column)
            columns_seen << column
            columns << column
          end
          values_by_column[column] << field.content.to_s
        else
          field.children.each do |subfield|
            column = "#{tag}$#{subfield.tag}"
            unless columns_seen.include?(column)
              columns_seen << column
              columns << column
            end
            values_by_column[column] << subfield.content.to_s
          end
        end
      end

      status = fields.empty? ? "MARC EMPTY" : "OK"
      rows << [manuscript["id"], manuscript["ext_id"], values_by_column.transform_values { |values| values.join(" | ") }]
      statuses << [manuscript["id"], manuscript["ext_id"], status, fields.length]
    end

    spreadsheet = RODF::Spreadsheet.new
    values_table = spreadsheet.table("PSMD manuscripts")
    write_row(values_table, *(RECORD_HEADERS + columns))
    rows.each do |manuscript_id, ext_id, values|
      write_row(values_table, manuscript_id, ext_id, *columns.map { |column| values[column] || "" })
    end

    status_table = spreadsheet.table("Record status")
    write_row(status_table, *RECORD_HEADERS, "MARC status", "Parsed field count")
    statuses.each { |row| write_row(status_table, *row) }

    FileUtils.mkdir_p(File.dirname(File.expand_path(output_path)))
    spreadsheet.write_to(output_path)
    warn "Wrote #{output_path} (#{manuscripts.length} manuscripts, #{columns.length} MARC tag/subfield columns)"
  end

  private

  def write_row(table, *values)
    row = table.row
    values.each { |value| row.cell(value.to_s) }
  end
end

ExportAllManuscriptSubfields.run
