require "csv"
require "json"

USAGE = <<~HELP
  Print the configured MARC tags for manuscript/source editor profiles.

  Usage:
    rails runner housekeeping/psmd/print_manuscript_tag_configuration.rb OUTPUT.csv

  Every manuscript/source profile is exported using the current locale.
HELP

def profile_id(profile)
  profile.respond_to?(:id) ? profile.id.to_s : ""
end

def profile_name(profile)
  profile.respond_to?(:name) ? profile.name.to_s : profile_id(profile)
end

def profile_model(profile)
  profile.respond_to?(:model) ? profile.model.to_s : ""
end

def manuscript_profiles
  profiles = EditorConfiguration.profiles.to_a
  model_profiles = profiles.select do |profile|
    ["manuscript", "source"].include?(profile_model(profile))
  end

  # Profiles in older applications do not expose a model because every
  # profile belongs to Manuscript. In that case, retain all profiles.
  model_profiles.empty? ? profiles : model_profiles
end

def hash_value(hash, key)
  return nil unless hash.respond_to?(:[])
  hash[key] || hash[key.to_s] || hash[key.to_sym]
end

def configured_tags(profile)
  labels = profile.labels_config || {}
  options = profile.options_config || {}

  (labels.keys + options.keys).map(&:to_s)
    .select { |key| key =~ /\A\d{3}\z/ }
    .uniq.sort
end

def translated_tag_label(profile, tag)
  profile.get_label(tag).to_s
rescue StandardError
  tag_config = hash_value(profile.labels_config, tag) || {}
  localized_label(hash_value(tag_config, :label))
end

def translated_subfield_label(profile, tag, subfield)
  profile.get_sub_label(tag, subfield).to_s
rescue StandardError
  tag_config = hash_value(profile.labels_config, tag) || {}
  fields = hash_value(tag_config, :fields) || {}
  field_config = hash_value(fields, subfield) || {}
  localized_label(hash_value(field_config, :label))
end

def localized_label(value)
  return "" if value.nil?
  return value.to_s unless value.respond_to?(:[])

  locale = I18n.locale.to_s
  value[locale] || value[locale.to_sym] || value["en"] || value[:en] || ""
end

def field_options(tag_options)
  layout = hash_value(tag_options, "layout") || {}
  fields = hash_value(layout, "fields") || []

  fields.each_with_object({}) do |field_entry, result|
    next unless field_entry.respond_to?(:[]) && field_entry[0]
    result[field_entry[0].to_s] = field_entry[1] || {}
  end
end

def label_subfields(profile, tag)
  tag_config = hash_value(profile.labels_config || {}, tag) || {}
  fields = hash_value(tag_config, :fields) || {}
  fields.respond_to?(:keys) ? fields.keys.map(&:to_s) : []
end

def subfields_for(profile, tag, tag_options)
  fields = (label_subfields(profile, tag) + field_options(tag_options).keys).uniq

  fields.sort.map do |subfield|
    prefix = subfield == "indicator" ? "indicator" : "$#{subfield}"
    label = translated_subfield_label(profile, tag, subfield)
    label.empty? ? prefix : "#{prefix} #{label}"
  end.join("; ")
end

def parameters_for(tag_options)
  parameters = hash_value(tag_options, "tag_params")
  parameters.nil? || parameters.empty? ? "" : JSON.generate(parameters)
end

output_path = ARGV.shift
abort USAGE unless output_path && ARGV.empty?

profiles = manuscript_profiles

row_count = 0
CSV.open(output_path, "wb") do |csv|
  csv << ["Profile", "Tag", "Label", "Subfields", "Parameters"]

  profiles.sort_by { |profile| [profile_name(profile), profile_id(profile)] }.each do |profile|
    configured_tags(profile).each do |tag|
      tag_options = hash_value(profile.options_config || {}, tag) || {}
      csv << [
        profile_name(profile),
        tag,
        translated_tag_label(profile, tag),
        subfields_for(profile, tag, tag_options),
        parameters_for(tag_options)
      ]
      row_count += 1
    end
  end
end

warn "Wrote #{row_count} configured tags to #{output_path}"
