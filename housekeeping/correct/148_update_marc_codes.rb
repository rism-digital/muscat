require "csv"
require "optparse"

USAGE = <<~HELP
148_update_marc_codes.rb

Update authority identifiers stored in MARC fields.

Usage

  # Add missing identifiers
  rails r 148_update_marc_codes.rb add \
    --model Place \
    --field 024a \
    --code TGN \
    input.csv

  CSV format:
    muscat_id,new_code

  Behaviour:
    - Adds the identifier if none exists.
    - Reports UNCHANGED if already present.
    - Reports CHANGED if a different identifier already exists (does not overwrite).

  # Replace a specific identifier
  rails r 148_update_marc_codes.rb replace \
    --model Person \
    --field 024a \
    --code WKP \
    input.csv

  CSV format:
    muscat_id,old_code,new_code

  Behaviour:
    - Replaces only the matching old_code.
    - If old_code is not found, adds new_code.
    - Other duplicate identifiers remain untouched.

Options

  --model MODEL           ActiveRecord model (Place, Person, Source, ...)
  --field TAGSUBFIELD     MARC field/subfield to update (e.g. 024a, 035a)
  --code VALUE            Authority code (TGN, WKP, ICCU, ISNI, ...)
  --code-subfield SUB     Subfield containing the authority code (default: 2)

Output (TSV)

  muscat_id    identifier    status    optional_message

Statuses

  ADDED
  UPDATED
  UNCHANGED
  CHANGED
  RECORD DELETED
HELP

mode = ARGV.shift

unless %w(add replace).include?(mode)
  puts USAGE
  exit
end

options = {
  code_subfield: "2"
}

OptionParser.new do |opts|
  opts.on("--model MODEL")          { |v| options[:model] = v }
  opts.on("--field FIELD")          { |v| options[:field] = v }
  opts.on("--code CODE")            { |v| options[:code] = v }
  opts.on("--code-subfield SUB")    { |v| options[:code_subfield] = v }
  opts.on("-h", "--help") do
    puts USAGE
    exit
  end
end.parse!

filename = ARGV.shift

unless filename &&
       options[:model] &&
       options[:field] &&
       options[:code]
  puts USAGE
  exit
end

model = options[:model].constantize

field_tag = options[:field][0,3]
field_sub = options[:field][3]
code_sub  = options[:code_subfield]

def output_tsv_line(*args)
  puts CSV.generate_line(args, col_sep: "\t")
end

def matching_fields(marc, tag, code_sub, code)
  (marc[tag] || []).select do |t|
    t[code_sub]&.first&.content.to_s.strip == code
  end
end

CSV.foreach(filename) do |row|

  muscat_id = row[0].to_s.strip
  next if muscat_id.empty?

  begin
    rec = model.find(muscat_id)
  rescue ActiveRecord::RecordNotFound
    output_tsv_line muscat_id, "", "RECORD DELETED"
    next
  end

  fields = matching_fields(rec.marc, field_tag, code_sub, options[:code])

  if mode == "add"

    new_code = row[1].to_s.strip
    next if new_code.empty?

    existing = fields.first

    if existing

      old_code = existing[field_sub]&.first&.content.to_s.strip

      if old_code == new_code
        output_tsv_line muscat_id, new_code, "UNCHANGED"
      else
        output_tsv_line muscat_id, new_code, "CHANGED", "old:#{old_code}"
      end

      next
    end

    rec.marc.add_tag_with_subfields(
      field_tag,
      field_sub.to_sym => new_code,
      code_sub.to_sym => options[:code]
    )

    rec.paper_trail_event = "Add #{options[:code]} #{new_code} in #{options[:field]}"
    rec.save

    output_tsv_line muscat_id, new_code, "ADDED"

  else # replace

    old_code = row[1].to_s.strip
    new_code = row[2].to_s.strip

    next if new_code.empty?

    target = fields.find do |t|
      t[field_sub]&.first&.content.to_s.strip == old_code
    end

    if target

      target[field_sub].first.content = new_code

      rec.paper_trail_event =
        "Replace #{options[:code]} #{old_code} to #{new_code} in #{options[:field]}"

      rec.save

      output_tsv_line muscat_id, new_code, "UPDATED"

    else

      rec.marc.add_tag_with_subfields(
        field_tag,
        field_sub.to_sym => new_code,
        code_sub.to_sym => options[:code]
      )

      rec.paper_trail_event = "Add #{options[:code]} #{new_code} in #{options[:field]}"
      rec.save

      output_tsv_line muscat_id, new_code, "ADDED"

    end

  end

end