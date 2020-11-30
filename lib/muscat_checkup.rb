require 'stringio'
require 'set'

class MuscatCheckup  

  def initialize(options = {})
      @parallel_jobs = options.include?(:jobs) ? options[:jobs] : 10
      @all_src = options.include?(:limit) ? options[:limit] : Source.all.count
      @limit = @all_src / @parallel_jobs
      @folder = options.include?(:folder) ? options[:folder] : nil

      @limit_unknown_tags = true

      @skip_validation = (options.include?(:skip_validation) && options[:skip_validation] == true)
      @skip_dates = (options.include?(:skip_dates) && options[:skip_dates] == true)
      @skip_links = (options.include?(:skip_links) && options[:skip_links] == true)
      @skip_unknown_tags = (options.include?(:skip_unknown_tags) && options[:skip_unknown_tags] == true)
      @skip_holdings = (options.include?(:skip_holdings) && options[:skip_holdings] == true)
      @debug_logger = options.include?(:logger) ? options[:logger] : nil
  end

  def run_parallel()
    begin_time = Time.now
    
    String.disable_colorization true
=begin
    results = Parallel.map(0..@parallel_jobs, in_processes: @parallel_jobs) do |jobid|
      errors = {}
      validations = {}
      offset = @limit * jobid

      Source.order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
        s = Source.find(sid.id)
        begin
          ## Capture STDOUT and STDERR
          ## Only for the marc loading!
          $stdout = new_stdout
          $stderr = new_stdout
          
          s.marc.load_source true
          
          # Set back to original
          $stdout = old_stdout
          $stderr = old_stderr
          
          res = validate_record(s)
          validations[sid.id] = res if res && !res.empty?
        rescue
          ## Exit the capture
          $stdout = old_stdout
          $stderr = old_stderr
          
          errors[sid.id] = new_stdout.string
          new_stdout.rewind
        end
        
        s = nil
      end
      {errors: errors, validations: validations}
    end
=end

    if @folder
      @limit_unknown_tags = false
      results = validate_folder
    else
      results = validate_sources
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

  def load_and_validate_source(s)
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
      
      errors[s.id] = new_stdout.string
      if !new_stdout.string.strip.empty? && @debug_logger
        new_stdout.string.each_line do |line|
          next if line.strip.empty?
          @debug_logger.error "#{s.id} marc_error #{line.strip}"
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
      
      errors[sid.id] = new_stdout.string
      @debug_logger.error(new_stdout.string) if @debug_logger
      new_stdout.rewind
    end
    return errors, validations
  end

  def validate_sources
    results = Parallel.map(0..@parallel_jobs, in_processes: @parallel_jobs) do |jobid|
      errors = {}
      validations = {}
      offset = @limit * jobid

      Source.order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
        s = Source.find(sid.id)
        
        e, v = load_and_validate_source(s)
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

      e, v = load_and_validate_source(s)
      errors.merge!(e)
      validations.merge!(v)
      
      s = nil
    end
      
    [{errors: errors, validations: validations}]
  end

  def validate_record(record)

    begin
      validator = MarcValidator.new(record, nil, false, @debug_logger)
      validator.validate_tags if !@skip_validation
      validator.validate_dates if !@skip_dates
      validator.validate_links if !@skip_links
      validator.validate_unknown_tags if !@skip_unknown_tags
      validator.validate_holdings if !@skip_holdings
      return validator.get_errors
    rescue Exception => e
      puts e.message
      @debug_logger.err(e.message) if @debug_logger
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
                unknown_tags[key][:items] << id if unknown_tags[key][:items].count < 10 || @limit_unknown_tags == false
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
  
end
