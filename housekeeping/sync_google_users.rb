#!/usr/bin/env ruby

require "csv"

def normalize_email(value)
  value.to_s.strip.downcase
end

csv_path = ARGV[0]

if csv_path.nil? || csv_path.empty?
  warn "Usage: ruby housekeeping/sync_google_users.rb path/to/google_group.csv"
  exit 1
end

unless File.exist?(csv_path)
  warn "CSV file not found: #{csv_path}"
  exit 1
end

lines = File.readlines(csv_path, chomp: true)
if lines.empty?
  warn "CSV file is empty: #{csv_path}"
  exit 1
end

header_row_index = lines.first.include?(",") ? 0 : 1
if lines[header_row_index].nil?
  warn "CSV file does not contain a header row: #{csv_path}"
  exit 1
end

group_emails = CSV.parse(lines[header_row_index..].join("\n"), headers: true).each_with_object([]) do |row, emails|
  group_status = row["Group status"].to_s.strip.downcase
  email_status = row["Email status"].to_s.strip.downcase
  next if group_status == "banned" || email_status == "banned"

  email = normalize_email(row["Email address"])
  emails << email unless email.empty?
end.uniq

muscat_emails = User.where(disabled: false).where.not(email: [nil, ""]).pluck(:email).map do |email|
  normalize_email(email)
end.reject(&:empty?).uniq

disabled_muscat_emails = User.where(disabled: true).where.not(email: [nil, ""]).pluck(:email).map do |email|
  normalize_email(email)
end.reject(&:empty?).uniq

all_muscat_emails = (muscat_emails + disabled_muscat_emails).uniq

emails_to_add = (muscat_emails - group_emails).sort
emails_to_remove = (group_emails - all_muscat_emails).sort

puts "TO ADD"
emails_to_add.each_slice(10).with_index do |group, index|
  puts group.join(", ")
  puts "" if index < (emails_to_add.size - 1) / 10
end
puts

puts "TO REMOVE"
puts emails_to_remove.join("\n")
puts

puts "INVITE MESSAGE"
puts "Hello,"
puts
puts "We are happy to invite you to the Muscat user group."
