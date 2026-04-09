require 'stringio'
require 'set'

class MuscatCheckup  

  # It was 10, but now we should have exclusions
  UNKNOWN_TAG_LIMIT = 100

  def initialize(options = {})
    @model = options[:model].is_a?(Class) ? options[:model] : Source

    @parallel_jobs = options.fetch(:jobs, 10)
    @all_items = options.fetch(:limit, @model.count)
    @folder = options[:folder]

    @debug_logger = options[:logger]

    @skip_validation            = options[:skip_validation] == true
    @skip_dates                 = options[:skip_dates] == true
    @skip_links                 = options[:skip_links] == true
    @skip_unknown_tags          = options[:skip_unknown_tags] == true
    @skip_holdings              = options[:skip_holdings] == true
    @skip_dead_774              = options[:skip_dead_774] == true
    @skip_dead_773              = options[:skip_dead_773] == true
    @skip_parent_institution    = options[:skip_parent_institution] == true
    @skip_588_validation        = options[:skip_588_validation] == true
    @skip_validate_work_status  = options[:skip_validate_work_status] == true
    @skip_parent_check          = options[:skip_parent_check] == true
    @skip_validate_person_codes = options[:skip_validate_person_codes] == true

    # These are relevant only for Sources
    if @model != Source
      @skip_holdings = true
      @skip_dead_774 = true
      @skip_dead_773 = true
      @skip_parent_institution = true
    end

    @skip_validate_person_codes = true if @model != Person

    @validation_exclusions =
      if options[:process_exclusions] == true
        ValidationExclusion.new(@model)
      end
  end

  def validate_parallel
    String.disable_colorization true

    limit_unknown_tags = !@folder
    results = @folder ? validate_folder : validate_items

    # Extract and separate the errors and validations
    total_errors = {}
    total_validations = {}
    results.each do |r|
      total_errors.merge!(r[:errors])
      total_validations.merge!(r[:validations])
    end
        
    filtered_validations, foreign_tag_errors, unknown_tags = postprocess_results(total_validations, limit_unknown_tags: limit_unknown_tags)
    return total_errors, filtered_validations, foreign_tag_errors, unknown_tags

  end
  
  private

  def load_and_validate_item(s)
    # Capture all the puts from the inner classes
    old_stdout = $stdout
    old_stderr = $stderr

    errors = {}
    validations = {}

    begin
      ## Capture STDOUT and STDERR
      ## Only for the marc loading!
      new_stdout = StringIO.new
      $stdout = new_stdout
      $stderr = new_stdout
      
      s.marc.load_source true
      
      errors[s.id] = new_stdout.string if !new_stdout.string.strip.empty?
      if !new_stdout.string.strip.empty? && @debug_logger
        new_stdout.string.each_line do |line|
          next if line.strip.empty?
          @debug_logger.error("record_error #{s.id} #{print_record_type(s)} no_tag no_subtag #{line.strip}") if @debug_logger

        end
      end

      # Set back to original
      $stdout = old_stdout
      $stderr = old_stderr
      new_stdout.rewind
      
      res = validate_record(s)
      validations[s.id] = res if res && !res.empty?
    rescue
      ## Exit the capture
      $stdout = old_stdout
      $stderr = old_stderr
      
      errors[s.id] = new_stdout.string if !new_stdout.string.strip.empty?
      #@debug_logger.error(new_stdout.string) if @debug_logger

      if !new_stdout.string.strip.empty? && @debug_logger
        new_stdout.string.each_line do |line|
          next if line.strip.empty?
          @debug_logger.error("record_exception #{s.id} #{print_record_type(s)} no_tag no_subtag #{line.strip}") if @debug_logger

        end
      end

      new_stdout.rewind
    end
    return errors, validations
  end

  def validate_items
    batch_size = (@all_items.to_f / @parallel_jobs).ceil

    Parallel.map(0...@parallel_jobs, in_processes: @parallel_jobs) do |jobid|
      errors = {}
      validations = {}

      offset = batch_size * jobid
      
      @model.order(:id).limit(batch_size).offset(offset).select(:id).each do |sid|
        s = @model.find(sid.id)
        
        e, v = load_and_validate_item(s)
        errors.merge!(e)
        validations.merge!(v)
        
        s = nil
      end

      { errors: errors, validations: validations }
    end
  end

  def validate_folder
    errors = {}
    validations = {}

    @folder.folder_items.each do |fi|
      next if !fi.item
      s = fi.item

      e, v = load_and_validate_item(s)
      errors.merge!(e)
      validations.merge!(v)
      
      s = nil
    end
      
    [{errors: errors, validations: validations}]
  end

  def validate_record(record)

    begin
      validator = MarcValidator.new(record, nil, false, @debug_logger, @validation_exclusions)
      validator.validate_tags               if !@skip_validation
      validator.validate_dates              if !@skip_dates
      validator.validate_links              if !@skip_links
      validator.validate_unknown_tags       if !@skip_unknown_tags
      validator.validate_holdings           if !@skip_holdings
      validator.validate_dead_774_links     if !@skip_dead_774
      validator.validate_dead_773_links     if !@skip_dead_773
      validator.validate_parent_institution if !@skip_parent_institution
      validator.validate_588                if !@skip_588_validation
      validator.validate_work_status        if !@skip_validate_work_status
      validator.validate_template_harmony   if !@skip_parent_check
      validator.validate_person_codes       if !@skip_validate_person_codes
      return validator.get_errors
    rescue Exception => e
      puts e.message
      @debug_logger.error("validation_exception #{record.id} #{print_record_type(record)} no_tag no_subtagtag #{e.message}") if @debug_logger
    end
    
  end
  
  def postprocess_results(validations, limit_unknown_tags: true, unknown_tag_limit: UNKNOWN_TAG_LIMIT)
    foreign_tag_errors = Set.new
    unknown_tags = {}

    filtered_validations = validations.each_with_object({}) do |(id, errors), filtered_errors|
      kept_tags = errors.each_with_object({}) do |(tag, subtags), kept_subtags_by_tag|
        kept_subtags = subtags.each_with_object({}) do |(subtag, messages), kept_messages_by_subtag|
          kept_messages = messages.reject do |message|
            if foreign_tag_message?(message)
              foreign_tag_errors.add("#{tag}#{subtag} #{normalize_foreign_tag_message(message)}")
              true
            elsif unknown_tag_message?(message)
              add_unknown_tag(unknown_tags, id, tag, subtag, message, limit_unknown_tags: limit_unknown_tags, unknown_tag_limit: unknown_tag_limit)
              true
            else
              false
            end
          end

          kept_messages_by_subtag[subtag] = kept_messages unless kept_messages.empty?
        end

        kept_subtags_by_tag[tag] = kept_subtags unless kept_subtags.empty?
      end

      filtered_errors[id] = kept_tags unless kept_tags.empty?
    end

    [filtered_validations, foreign_tag_errors.to_a, unknown_tags]
  end

  def foreign_tag_message?(message)
    message.include?("foreign-tag: different unresolved value:") ||
      message.include?("foreign-tag: tag not present in unresolved")
  end

  def normalize_foreign_tag_message(message)
    message.gsub("foreign-tag: different unresolved value:", "old val:")
  end

  def unknown_tag_message?(message)
    message.include?("Unknown tag in layout") ||
      message.include?("mandatory") ||
      message.include?("required")
  end

  def add_unknown_tag(unknown_tags, id, tag, subtag, message, limit_unknown_tags:, unknown_tag_limit:)
    key = "#{tag}-#{subtag}: #{message}"

    unknown_tags[key] ||= { count: 0, items: [] }
    unknown_tags[key][:count] += 1

    if !limit_unknown_tags || unknown_tags[key][:items].length < unknown_tag_limit
      unknown_tags[key][:items] << id
    end
  end
  
  def print_record_type(item)
    return "none" unless item.respond_to?(:get_record_type)
    item.get_record_type&.to_s || "none"
  end

end
