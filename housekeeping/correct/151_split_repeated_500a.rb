# frozen_string_literal: true

# Remove empty $a subfields and split repeated, non-empty $a subfields into
# separate fields for the configured tags in Source records.
#
# Run with:
#   rails runner housekeeping/correct/151_split_repeated_500a.rb
#
# Every updated source ID is written to stdout and the Rails log.

TAGS = %w[500 599].freeze
PAPER_TRAIL_NOTE = "Split repeated $a and remove empty $a in #{TAGS.join(', ')}"
LOG_PREFIX = "[151_split_repeated_500a]"

def split_repeated_a(marc, tags)
  stats = {
    empty_subfields_removed: 0,
    empty_fields_removed: 0,
    new_fields_created: 0
  }

  tags.each do |tag|
    # Work from a snapshot because new fields are inserted during iteration.
    marc[tag].dup.each do |field|
      empty_subfields = field["a"].select { |subfield| subfield.content.to_s.strip.empty? }
      empty_subfields.each(&:destroy_yourself)
      stats[:empty_subfields_removed] += empty_subfields.count

      remaining_subfields = field["a"]
      if remaining_subfields.empty?
        if field.children.empty?
          field.destroy_yourself
          stats[:empty_fields_removed] += 1
        end
        next
      end

      repeated_subfields = remaining_subfields.drop(1)
      next if repeated_subfields.empty?

      insert_at = marc.root.children.index(field) + 1

      repeated_subfields.each do |subfield|
        new_field = MarcNode.new("source", tag, "", field.indicator)
        new_field.add_at(MarcNode.new("source", "a", subfield.content, nil), 0)
        marc.root.add_at(new_field, insert_at)

        subfield.destroy_yourself
        insert_at += 1
        stats[:new_fields_created] += 1
      end
    end
  end

  stats
end

updated_count = 0
error_count = 0

tag_conditions = TAGS.map { "marc_source LIKE ?" }.join(" OR ")
tag_patterns = TAGS.map { |tag| "%=#{tag}%" }

Source.where("(#{tag_conditions})", *tag_patterns).where(id: 857003698).find_each do |source|
  begin
    puts source.marc
    puts
    stats = split_repeated_a(source.marc, TAGS)
    next if stats.values.sum.zero?
    puts source.marc
    source.paper_trail_event = PAPER_TRAIL_NOTE
    source.save!

    updated_count += 1
    puts source.id
    Rails.logger.info(
      "#{LOG_PREFIX} Source #{source.id}: " \
      "removed #{stats[:empty_subfields_removed]} empty $a subfield(s), " \
      "removed #{stats[:empty_fields_removed]} empty field(s), " \
      "created #{stats[:new_fields_created]} additional field(s) in #{TAGS.join(', ')}"
    )
  rescue StandardError => error
    error_count += 1
    warn "#{source.id}\tERROR\t#{error.message}"
    Rails.logger.error("#{LOG_PREFIX} Source #{source.id}: #{error.class}: #{error.message}")
  end
end

warn "Updated #{updated_count} source(s); errors: #{error_count}"
