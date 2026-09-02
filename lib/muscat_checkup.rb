require 'stringio'
require 'set'

class MuscatCheckupResult
  attr_reader :errors, :validations, :foreign_tag_errors, :unknown_tags, :observations

  def initialize(errors:, validations:, foreign_tag_errors:, unknown_tags:, observations:)
    @errors = errors
    @validations = validations
    @foreign_tag_errors = foreign_tag_errors
    @unknown_tags = unknown_tags
    @observations = observations
  end
end

class RecordCheckupResult
  attr_reader :errors, :validations, :findings

  def initialize(errors:, validations:, findings:)
    @errors = errors
    @validations = validations
    @findings = findings
  end
end

class TelemetryWorker
  def initialize(observability)
    @observations = {
      records_scanned: 0,
      records_with_findings: 0,
      findings: Hash.new(0)
    }
    @event_stream = ValidationObservability::EventStream.new(**observability)
  end

  def collect_findings?
    true
  end

  def technical_findings(output:, exception:, phase:)
    findings = []

    if output.strip.present?
      category = exception ? "record_exception_#{phase}" : "record_error"
      findings << technical_finding(category, output.strip)
    end

    if exception
      findings << technical_finding("record_exception_#{phase}", exception.message)
    end

    findings
  end

  attr_reader :observations

  def record(record, findings)
    @observations[:records_scanned] += 1
    return if findings.empty?

    record_type = print_record_type(record)
    @event_stream.validation_message(
      record_id: record.id,
      record_type: record_type,
      findings: findings
    )

    @observations[:records_with_findings] += 1
    findings.each do |finding|
      @observations[:findings][[record_type, finding[:category]]] += 1
    end
  end

  private

  def print_record_type(record)
    return "none" unless record.respond_to?(:get_record_type)
    record.get_record_type&.to_s || "none"
  end

  def technical_finding(category, message)
    {
      tag: "no_tag",
      subtag: "no_subtag",
      message: message.to_s,
      category: category
    }
  end
end

class MuscatCheckup  

  # It was 10, but now we should have exclusions
  UNKNOWN_TAG_LIMIT = 100
  EMPTY_OBSERVATIONS = {
    records_scanned: 0,
    records_with_findings: 0,
    findings: {}.freeze
  }.freeze

  def initialize(options = {})
    @model = options[:model].is_a?(Class) ? options[:model] : Source

    @parallel_jobs = options.fetch(:jobs, 10)
    @all_items = options.fetch(:limit, @model.count)
    @folder = options[:folder]

    @debug_logger = options[:logger]
    @observability = options[:observability]
    @telemetry_enabled = @observability.present?

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
    observations = { records_scanned: 0, records_with_findings: 0, findings: Hash.new(0) }
    results.each do |r|
      total_errors.merge!(r[:errors])
      total_validations.merge!(r[:validations])
      observations[:records_scanned] += r[:observations][:records_scanned]
      observations[:records_with_findings] += r[:observations][:records_with_findings]
      r[:observations][:findings].each { |key, count| observations[:findings][key] += count }
    end
        
    filtered_validations, foreign_tag_errors, unknown_tags = postprocess_results(total_validations, limit_unknown_tags: limit_unknown_tags)
    MuscatCheckupResult.new(
      errors: total_errors,
      validations: filtered_validations,
      foreign_tag_errors: foreign_tag_errors,
      unknown_tags: unknown_tags,
      observations: observations
    )

  end
  
  private

  def load_and_validate_item(s)
    errors = {}
    validations = {}

    phase = :load

    result, output, exception = capture_stdout_and_stderr do
      #s.marc.load_source(true)
      phase = :validate
      validate_record(s)
    end

    unless output.strip.empty?
      errors[s.id] = output
      log_output_lines(output, s, exception ? "record_exception_#{phase}" : "record_error")
    end

    if exception
      append_exception(errors, s.id, exception)
      @debug_logger.error("[#{phase}] #{exception.backtrace.first(2).join("\n")}") if @debug_logger
      puts "[#{phase}] #{exception.backtrace.first(2).join("\n")}" # Also print the message on the stdout sink 
    elsif result.present?
      validations[s.id] = result
    end

    [errors, validations]
  end

  def load_and_validate_item_with_telemetry(s, telemetry)
    errors = {}
    validations = {}
    findings = []

    phase = :load

    result, output, exception = capture_stdout_and_stderr do
      phase = :validate
      validate_record_with_telemetry(s, telemetry)
    end

    unless output.strip.empty?
      errors[s.id] = output
      log_output_lines(output, s, exception ? "record_exception_#{phase}" : "record_error")
    end

    if exception
      append_exception(errors, s.id, exception)
      @debug_logger.error("[#{phase}] #{exception.backtrace.first(2).join("\n")}") if @debug_logger
      puts "[#{phase}] #{exception.backtrace.first(2).join("\n")}"
    elsif result.present?
      validations[s.id] = result.validations if result.validations.present?
      findings.concat(result.findings)
    end

    findings.concat(
      telemetry.technical_findings(
        output: output,
        exception: exception,
        phase: phase
      )
    )

    RecordCheckupResult.new(errors: errors, validations: validations, findings: findings)
  end

  def capture_stdout_and_stderr
    old_stdout = $stdout
    old_stderr = $stderr
    buffer = StringIO.new

    result = nil
    exception = nil

    begin
      $stdout = buffer
      $stderr = buffer
      result = yield
    rescue => e
      exception = e
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
    end

    [result, buffer.string, exception]
  end

  def append_exception(errors, id, exception)
    backtrace = exception.backtrace.first(2).join("\n")

    errors[id] ||= ""
    errors[id] << "\n" unless errors[id].empty?
    errors[id] << exception.message
    errors[id] << "\n"
    errors[id] << backtrace
  end

  def log_output_lines(output, s, prefix)
    return if output.strip.empty?
    return unless @debug_logger

    output.each_line do |line|
      next if line.strip.empty?
      @debug_logger.error("#{prefix} #{s.id} #{print_record_type(s)} no_tag no_subtag #{line.strip}")
    end
  end

  def validate_items
    return validate_items_with_telemetry if telemetry_enabled?
    validate_items_without_telemetry
  end

  def validate_items_without_telemetry
    batch_size = (@all_items.to_f / @parallel_jobs).ceil

    Parallel.map(0...@parallel_jobs, in_processes: @parallel_jobs) do |jobid|
      errors = {}
      validations = {}

      offset = batch_size * jobid
      ids = @model.order(:id).limit(batch_size).offset(offset).pluck(:id)

      ids.each_slice(1000) do |slice|
        @model.where(id: slice).order(:id).each do |s|
          errors_for_record, validations_for_record = load_and_validate_item(s)
          errors.merge!(errors_for_record)
          validations.merge!(validations_for_record)
        end
      end

      {
        errors: errors,
        validations: validations,
        observations: EMPTY_OBSERVATIONS
      }
    end
  end

  def validate_items_with_telemetry
    batch_size = (@all_items.to_f / @parallel_jobs).ceil

    Parallel.map(0...@parallel_jobs, in_processes: @parallel_jobs) do |jobid|
      errors = {}
      validations = {}
      telemetry = build_telemetry_worker

      offset = batch_size * jobid
      ids = @model.order(:id).limit(batch_size).offset(offset).pluck(:id)

      ids.each_slice(1000) do |slice|
        @model.where(id: slice).order(:id).each do |s|
          result = load_and_validate_item_with_telemetry(s, telemetry)
          errors.merge!(result.errors)
          validations.merge!(result.validations)
          telemetry.record(s, result.findings)
        end
      end

      {
        errors: errors,
        validations: validations,
        observations: telemetry.observations
      }
    end
  end

  def validate_folder
    return validate_folder_with_telemetry if telemetry_enabled?
    validate_folder_without_telemetry
  end

  def validate_folder_without_telemetry
    errors = {}
    validations = {}

    @folder.folder_items.each do |fi|
      next if !fi.item
      s = fi.item

      errors_for_record, validations_for_record = load_and_validate_item(s)
      errors.merge!(errors_for_record)
      validations.merge!(validations_for_record)

      s = nil
    end

    [{ errors: errors, validations: validations, observations: EMPTY_OBSERVATIONS }]
  end

  def validate_folder_with_telemetry
    errors = {}
    validations = {}
    telemetry = build_telemetry_worker

    @folder.folder_items.each do |fi|
      next if !fi.item
      s = fi.item

      result = load_and_validate_item_with_telemetry(s, telemetry)
      errors.merge!(result.errors)
      validations.merge!(result.validations)
      telemetry.record(s, result.findings)

      s = nil
    end

    [{ errors: errors, validations: validations, observations: telemetry.observations }]
  end

  def validate_record(record)
    validator = MarcValidator.new(record, nil, false, @debug_logger, @validation_exclusions)
    run_record_validations(validator)
    validator.get_errors
  end

  def validate_record_with_telemetry(record, telemetry)
    # if something is wrong, let the validator throw and it will be caught by the logger
    validator = MarcValidator.new(record, nil, false, @debug_logger, @validation_exclusions, collect_findings: telemetry.collect_findings?)
    run_record_validations(validator)
    RecordCheckupResult.new(
      errors: {},
      validations: validator.get_errors,
      findings: validator.get_findings
    )
  end

  def run_record_validations(validator)
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

  def build_telemetry_worker
    TelemetryWorker.new(@observability)
  end

  def telemetry_enabled?
    @telemetry_enabled
  end

end
