require 'stringio'
require 'set'

class MuscatCheckup  

    def initialize(options = {})
        @parallel_jobs = 10
        @all_src = options.include?(:limit) ? options[:limit] : Source.all.count
        @limit = @all_src / @parallel_jobs

        @skip_validation = (options.include?(:skip_validation) && options[:skip_validation] == true)
        @skip_dates = (options.include?(:skip_dates) && options[:skip_dates] == true)
        @skip_links = (options.include?(:skip_links) && options[:skip_links] == true)
        @skip_unknown_tags = (options.include?(:skip_unknown_tags) && options[:skip_unknown_tags] == true)
    end

  def run_parallel()
    # Capture all the puts from the inner classes
    new_stdout = StringIO.new
    old_stdout = $stdout
    old_stderr = $stderr

    begin_time = Time.now
    
    String.disable_colorization true
    
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
        
      end
      {errors: errors, validations: validations}
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
  def validate_record(record)

    begin
      validator = MarcValidator.new(record, false)
      validator.validate if !@skip_validation
      validator.validate_dates if !@skip_dates
      validator.validate_links if !@skip_links
      validator.validate_unknown_tags if !@skip_unknown_tags
      return validator.get_errors
    rescue Exception => e
      puts e.message
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
                unknown_tags[key][:items] << id if unknown_tags[key][:items].count < 10
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
