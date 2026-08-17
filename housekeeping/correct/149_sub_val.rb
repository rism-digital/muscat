require "csv"

USAGE = <<~HELP
  Usage:
    rails runner housekeeping/correct/149_sub_val.rb MODEL TAGSUBFIELD FILE

  Example:
    rails runner housekeeping/correct/149_sub_val.rb Source 852z vals.csv

  CSV columns:
    muscat_id,old_val,new_val
HELP

model_name, field, filename = ARGV

unless model_name && field&.match?(/\A\d{3}[0-9A-Za-z]\z/) && filename
  warn USAGE
  exit 1
end

model = model_name.constantize
tag = field[0, 3]
subtag = field[3]

CSV.foreach(filename, headers: true) do |row|
  muscat_id = row[0]&.strip
  old_val = row[1]
  new_val = row[2]

  if muscat_id.to_s.empty? || old_val.nil? || new_val.nil?
    warn "Skipping invalid row: #{row.inspect}"
    next
  end

  record = model.find_by(id: muscat_id)
  unless record
    puts [muscat_id, "RECORD DELETED"].to_csv(col_sep: "\t")
    next
  end

  substitutions = 0

  (record.marc[tag] || []).each do |marc_tag|
    (marc_tag[subtag] || []).each do |marc_subtag|
      next unless marc_subtag.content.to_s == old_val

      marc_subtag.content = new_val
      substitutions += 1
    end
  end

  if substitutions.positive?
    record.paper_trail_event = "Replace #{old_val} with #{new_val} in #{field}"
    record.save!
    puts [muscat_id, "UPDATED", substitutions].to_csv(col_sep: "\t")
  else
    puts [muscat_id, "NOT FOUND"].to_csv(col_sep: "\t")
  end
end
