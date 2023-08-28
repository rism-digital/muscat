require 'stringio'
require 'set'

class MuscatCheckup  

  # It was 10, but now we should have exclusions
  UNKNOWN_TAG_LIMIT = 100

  def initialize(options = {})
      @model = options.include?(:model) && options[:model].is_a?(Class) ? options[:model] : Source

      @parallel_jobs = options.include?(:jobs) ? options[:jobs] : 10
      @all_items = options.include?(:limit) ? options[:limit] : @model.all.count
      @limit = @all_items / @parallel_jobs
      @folder = options.include?(:folder) ? options[:folder] : nil

      @limit_unknown_tags = true

      @skip_validation = (options.include?(:skip_validation) && options[:skip_validation] == true)
      @skip_dates = (options.include?(:skip_dates) && options[:skip_dates] == true)
      @skip_links = (options.include?(:skip_links) && options[:skip_links] == true)
      @skip_unknown_tags = (options.include?(:skip_unknown_tags) && options[:skip_unknown_tags] == true)
      @skip_holdings = (options.include?(:skip_holdings) && options[:skip_holdings] == true)
      @skip_dead_774 = (options.include?(:skip_dead_774) && options[:skip_dead_774] == true)
      @skip_parent_institution = (options.include?(:skip_parent_institution) && options[:skip_parent_institution] == true)
      @debug_logger = options.include?(:logger) ? options[:logger] : nil

      # These are relevant only for Sources
      @skip_holdings = true if !@model.is_a?(Source)
      @skip_dead_774 = true if !@model.is_a?(Source)
      @skip_parent_institution = true if !@model.is_a?(Source)

      # Generate the exclusion matcher
      @validation_exclusions = (options.include?(:process_exclusions) && options[:process_exclusions] == true) ? ValidationExclusion.new(@model) : nil
  end

  def run_parallel()
    begin_time = Time.now
    
    String.disable_colorization true
    
    if @folder
      @limit_unknown_tags = false
      results = validate_folder
    else
      results = validate_items
    end

    # Extract and separate the errors and validations
    total_errors = {}
    total_validations = {}
    results.each do |r|
      total_errors.merge!(r[:errors])
      total_validations.merge!(r[:validations])
    end
    
    foreign_tag_errors, unknown_tags = postprocess_results!(total_validations)
    return total_errors, total_validations, foreign_tag_errors, unknown_tags
    
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
    results = Parallel.map(0..@parallel_jobs, in_processes: @parallel_jobs) do |jobid|
      errors = {}
      validations = {}
      offset = @limit * jobid

      @model.order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
        s = @model.find(sid.id)
        
        e, v = load_and_validate_item(s)
        errors.merge!(e)
        validations.merge!(v)
        
        s = nil
      end
      {errors: errors, validations: validations}
    end
    results
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
      validator.validate_tags if !@skip_validation
      validator.validate_dates if !@skip_dates
      validator.validate_links if !@skip_links
      validator.validate_unknown_tags if !@skip_unknown_tags
      validator.validate_holdings if !@skip_holdings
      validator.validate_dead_774_links if !@skip_dead_774
      validator.validate_parent_institution if !@skip_parent_institution
      return validator.get_errors
    rescue Exception => e
      puts e.message
      @debug_logger.error("validation_exception #{record.id} #{print_record_type(record)} no_tag no_subtagtag #{e.message}") if @debug_logger
    end
    
  end
  
  def postprocess_results!(validations)
    foreign_tag_errors = Set.new
    unknown_tags = {}

    validations.delete_if do |id, errors|
      errors.delete_if do |tag, subtags|
        subtags.delete_if do |subtag, messages|
          messages.delete_if do |message|
            if message.include?("foreign-tag: different unresolved value:") ||
              message.include?("foreign-tag: tag not present in unresolved")
              # Keep the error but make the message smaller
              foreign_tag_errors.add(tag + subtag + " " + message.gsub("foreign-tag: different unresolved value:", "old val:"))
              true
            elsif message.include?("Unknown tag in layout") || message.include?("mandatory") || message.include?("required")
              key = "#{tag}-#{subtag}: #{message}"
              if unknown_tags.key?(key)
                unknown_tags[key][:count] = unknown_tags[key][:count] + 1
                unknown_tags[key][:items] << id if unknown_tags[key][:items].count < UNKNOWN_TAG_LIMIT || @limit_unknown_tags == false
              else
                unknown_tags[key] = {count: 1, items: [id]}
              end
              true
            end
          end
          true if messages.length == 0
        end
        true if subtags.length == 0
      end
      true if errors.length == 0
    end
    
    [foreign_tag_errors.to_a, unknown_tags]
  end
  
  def print_record_type(item)
    if item.respond_to?(:get_record_type)
      return item.get_record_type.to_s
    else
      return "none"
    end
  end

end
