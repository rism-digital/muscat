Source.find_in_batches do |batch|
  batch.each do |s|
    validator = MarcValidator.new(s, false)
    validator.validate
    validator.validate_links
    validator.validate_unknown_tags
    puts validator.to_s if validator.has_errors
  end
end