
class MuscatCheckupReportJob < ApplicationJob
  queue_as :default
  
  def initialize(mdl = Source, telemetry: false)
    super
    @model = mdl != nil && mdl.is_a?(Class) ? mdl : Source
    @telemetry = telemetry
  end

  def perform()
    begin_time = Time.now
    observability = ValidationObservability.new if @telemetry
    stream = observability.start_run!(model: @model, started_at: begin_time) if @telemetry
  
    # For compatibility with older versions, validation.log is always for sources
    file_name = @model.is_a?(Source) ? "validation.log" : "#{@model.to_s.underscore.downcase}_validation.log"

    log_path = "#{Rails.root}/log/#{file_name}"
    logger = Logger.new(File.new(log_path, 'w'))
    logger.datetime_format = 
    logger.formatter = proc do |severity, datetime, progname, msg|
      #time = datetime.utc.strftime('%Y-%m-%d %H:%M:%SZ')
      #"[#{time}] [#{'%8s' % severity}] #{msg}\n"
      "#{msg}\n"
    end

    begin
      # Run the checkup function
      checkup_options = { model: @model, logger: logger, log_path: log_path, process_exclusions: true }
      checkup_options[:observability] = stream.metadata if @telemetry
      results = MuscatCheckup.new(checkup_options).validate_parallel
      total_errors, total_validations, foreign_tag_errors, unknown_tags, observations = results

      end_time = Time.now
      duration = (end_time - begin_time).to_i
      human_readable = format("%02d:%02d:%02d", duration / 3600, (duration % 3600) / 60, duration % 60)
      message = "#{@model.to_s} report started at #{begin_time.to_s}, (execution time: #{duration} seconds, or in human terms: #{human_readable})"

      if @telemetry
        observability.complete!(
          stream: stream,
          started_at: begin_time,
          completed_at: end_time,
          observations: observations
        )
      end
    rescue StandardError => e
      if @telemetry
        begin
          stream.run_failed(e)
        rescue StandardError => event_error
          Rails.logger.error("validation_observability_failure_event_failed model=#{@model} error=#{event_error.class}: #{event_error.message}")
        end
      end
      raise
    end

    HealthReport.notify(@model.to_s, message, total_errors, total_validations, foreign_tag_errors, unknown_tags).deliver_now
  end
  
end
