require "json"
require "pathname"
require "securerandom"
require "tempfile"
require "time"

# Writes monitoring artifacts for complete, scheduled Muscat checkups. It is
# deliberately file based: checkup jobs are short-lived processes, while Alloy
# can reliably collect durable local files.
class ValidationObservability
  DEFAULT_PROMETHEUS_TEXTFILE = Rails.root.join("log", "validation_metrics.prom").freeze
  DEFAULT_LOKI_LOG = Rails.root.join("log", "validation_observability.jsonl").freeze

  def initialize(prometheus_textfile: ENV.fetch("MUSCAT_VALIDATION_PROMETHEUS_TEXTFILE", DEFAULT_PROMETHEUS_TEXTFILE.to_s),
                 loki_log: ENV.fetch("MUSCAT_VALIDATION_LOKI_LOG", DEFAULT_LOKI_LOG.to_s))
    @prometheus_textfile = Pathname.new(prometheus_textfile)
    @loki_log = Pathname.new(loki_log)
  end

  def start_run!(model:, started_at:)
    stream = EventStream.new(loki_log: @loki_log, run_id: SecureRandom.uuid, model: model.to_s)
    stream.run_started(started_at)
    stream
  rescue StandardError => e
    Rails.logger.error("validation_observability_export_failed model=#{model} error=#{e.class}: #{e.message}")
    raise
  end

  def complete!(stream:, started_at:, completed_at:, observations:)
    summary = summarize(observations)
    write_prometheus_textfile!(prometheus_path(stream.model), render_prometheus(stream.model, started_at, completed_at, summary))
    stream.run_completed(completed_at, summary.merge(duration_seconds: completed_at - started_at))
  rescue StandardError => e
    Rails.logger.error("validation_observability_export_failed model=#{stream.model} error=#{e.class}: #{e.message}")
    raise
  end

  private

  def summarize(observations)
    findings = Hash.new(0)
    observations.fetch(:findings, {}).each do |(record_type, category), count|
      findings[[normalise(record_type), normalise(category)]] += count
    end

    {
      records_scanned: observations.fetch(:records_scanned, 0),
      records_with_findings: observations.fetch(:records_with_findings, 0),
      findings: findings
    }
  end

  def write_prometheus_textfile!(path, contents)
    Tempfile.create(["validation_metrics", ".prom"], path.dirname.to_s) do |file|
      file.write(contents)
      file.flush
      file.fsync
      File.rename(file.path, path)
    end
  end

  def render_prometheus(model_name, started_at, completed_at, summary)
    labels = "model=\"#{escape_label(model_name)}\""
    lines = [
      "# HELP muscat_validation_last_run_completed_timestamp_seconds Unix timestamp of the latest completed scheduled validation run.",
      "# TYPE muscat_validation_last_run_completed_timestamp_seconds gauge",
      "muscat_validation_last_run_completed_timestamp_seconds{#{labels}} #{completed_at.to_f}",
      "# HELP muscat_validation_last_run_successful_timestamp_seconds Unix timestamp of the latest successfully exported scheduled validation run.",
      "# TYPE muscat_validation_last_run_successful_timestamp_seconds gauge",
      "muscat_validation_last_run_successful_timestamp_seconds{#{labels}} #{completed_at.to_f}",
      "# HELP muscat_validation_last_run_duration_seconds Duration of the latest scheduled validation run.",
      "# TYPE muscat_validation_last_run_duration_seconds gauge",
      "muscat_validation_last_run_duration_seconds{#{labels}} #{completed_at - started_at}",
      "# HELP muscat_validation_last_run_records_scanned Records scanned during the latest scheduled validation run.",
      "# TYPE muscat_validation_last_run_records_scanned gauge",
      "muscat_validation_last_run_records_scanned{#{labels}} #{summary[:records_scanned]}",
      "# HELP muscat_validation_last_run_records_with_findings Records with one or more validation findings in the latest run.",
      "# TYPE muscat_validation_last_run_records_with_findings gauge",
      "muscat_validation_last_run_records_with_findings{#{labels}} #{summary[:records_with_findings]}",
      "# HELP muscat_validation_last_run_findings Validation findings in the latest run, grouped by stable category and record type.",
      "# TYPE muscat_validation_last_run_findings gauge"
    ]

    summary[:findings].sort.each do |(record_type, category), count|
      finding_labels = [labels, "record_type=\"#{escape_label(record_type)}\"", "category=\"#{escape_label(category)}\""].join(",")
      lines << "muscat_validation_last_run_findings{#{finding_labels}} #{count}"
    end
    lines.join("\n") + "\n"
  end

  # Separate model files avoid one scheduled job removing the most recent
  # metrics written by the other model checkups.
  def prometheus_path(model_name)
    base = @prometheus_textfile.to_s
    base = base.delete_suffix(".prom")
    Pathname.new("#{base}_#{underscore(model_name)}.prom")
  end

  def underscore(value)
    value.to_s.gsub(/([a-z\d])([A-Z])/, "\\1_\\2").downcase
  end

  def escape_label(value)
    value.to_s.gsub("\\", "\\\\").gsub("\n", "\\n").gsub("\"", "\\\"")
  end

  def normalise(value)
    value.to_s.empty? ? "unknown" : value.to_s
  end

  class EventStream
    attr_reader :model, :run_id

    def initialize(loki_log:, run_id:, model:)
      @loki_log = Pathname.new(loki_log)
      @run_id = run_id
      @model = model
    end

    def metadata
      { loki_log: @loki_log.to_s, run_id: @run_id, model: @model }
    end

    def run_started(at)
      append(event: "validation_run_started", timestamp: timestamp(at))
    end

    def validation_message(record_id:, record_type:, findings:)
      append(
        event: "validation_message",
        timestamp: timestamp(Time.now),
        record_id: record_id,
        record_type: normalise(record_type),
        findings: findings
      )
    end

    def run_completed(at, summary)
      append(
        event: "validation_run_completed",
        timestamp: timestamp(at),
        duration_seconds: summary.fetch(:duration_seconds),
        records_scanned: summary.fetch(:records_scanned),
        records_with_findings: summary.fetch(:records_with_findings)
      )
    end

    def run_failed(error, at = Time.now)
      append(
        event: "validation_run_failed",
        timestamp: timestamp(at),
        error_class: error.class.to_s,
        error_message: error.message.to_s
      )
    end

    private

    def append(payload)
      event = { workflow: "scheduled_checkup", model: @model, run_id: @run_id }.merge(payload)

      File.open(@loki_log, "a") do |file|
        file.flock(File::LOCK_EX)
        file.write(JSON.generate(event))
        file.write("\n")
        file.flush
      ensure
        file.flock(File::LOCK_UN) if file
      end
    end

    def normalise(value)
      value.to_s.empty? ? "unknown" : value.to_s
    end

    def timestamp(value)
      value.utc.iso8601(3)
    end
  end
end
