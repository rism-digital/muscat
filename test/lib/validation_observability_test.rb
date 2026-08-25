require "test_helper"
require "tmpdir"

class ValidationObservabilityTest < ActiveSupport::TestCase
  test "streams record failures before writing the Prometheus snapshot" do
    Dir.mktmpdir do |directory|
      metrics_path = File.join(directory, "validation_metrics.prom")
      loki_path = File.join(directory, "validation_observability.jsonl")
      started_at = Time.utc(2026, 8, 14, 9, 0, 0)
      completed_at = Time.utc(2026, 8, 14, 9, 0, 12)

      observability = ValidationObservability.new(
        prometheus_textfile: metrics_path,
        loki_log: loki_path
      )
      stream = observability.start_run!(model: Source, started_at: started_at)
      stream.validation_message(
        record_id: 123,
        record_type: :edition,
        findings: [
          { tag: "245", subtag: "a", message: "mandatory", category: "validation_error" },
          { tag: "260", subtag: "c", message: "Date in the future", category: "date_error" }
        ]
      )

      events_before_completion = File.readlines(loki_path).map { |line| JSON.parse(line) }
      assert_equal %w[validation_run_started validation_message], events_before_completion.map { |event| event.fetch("event") }
      assert_equal stream.run_id, events_before_completion.last.fetch("run_id")
      assert_equal 123, events_before_completion.last.fetch("record_id")
      assert_equal 2, events_before_completion.last.fetch("findings").length

      observability.complete!(
        stream: stream,
        started_at: started_at,
        completed_at: completed_at,
        observations: {
          records_scanned: 3,
          records_with_findings: 2,
          findings: {
            [:edition, "validation_error"] => 1,
            [:edition, "date_error"] => 1,
            ["unknown", "holding_error"] => 1
          }
        }
      )

      metrics = File.read(File.join(directory, "validation_metrics_source.prom"))
      assert_includes metrics, 'muscat_validation_last_run_records_scanned{model="Source"} 3'
      assert_includes metrics, 'muscat_validation_last_run_records_with_findings{model="Source"} 2'
      assert_includes metrics, 'muscat_validation_last_run_findings{model="Source",record_type="edition",category="validation_error"} 1'
      assert_includes metrics, 'muscat_validation_last_run_findings{model="Source",record_type="unknown",category="holding_error"} 1'

      events = File.readlines(loki_path).map { |line| JSON.parse(line) }
      assert_equal %w[validation_run_started validation_message validation_run_completed], events.map { |event| event.fetch("event") }
      assert_equal 3, events.last.fetch("records_scanned")

      work_stream = observability.start_run!(model: Work, started_at: started_at)
      observability.complete!(
        stream: work_stream,
        started_at: started_at,
        completed_at: completed_at,
        observations: { records_scanned: 0, records_with_findings: 0, findings: {} }
      )
      assert File.exist?(File.join(directory, "validation_metrics_source.prom"))
      assert File.exist?(File.join(directory, "validation_metrics_work.prom"))
    end
  end

  test "fails when the configured output directory does not exist" do
    path = File.join(Dir.mktmpdir, "missing", "validation_metrics.prom")

    assert_raises(Errno::ENOENT) do
      ValidationObservability.new(prometheus_textfile: path, loki_log: path.sub(".prom", ".jsonl")).start_run!(model: Source, started_at: Time.current)
    end
  end

  test "emits a failure lifecycle event" do
    Dir.mktmpdir do |directory|
      loki_path = File.join(directory, "validation_observability.jsonl")
      stream = ValidationObservability::EventStream.new(loki_log: loki_path, run_id: "run-failed", model: "Source")

      stream.run_failed(RuntimeError.new("database unavailable"))

      event = JSON.parse(File.read(loki_path))
      assert_equal "validation_run_failed", event.fetch("event")
      assert_equal "RuntimeError", event.fetch("error_class")
      assert_equal "database unavailable", event.fetch("error_message")
    end
  end

  test "serializes concurrent worker event writers into complete JSON lines" do
    Dir.mktmpdir do |directory|
      loki_path = File.join(directory, "validation_observability.jsonl")
      worker_pids = 2.times.map do |index|
        fork do
          stream = ValidationObservability::EventStream.new(loki_log: loki_path, run_id: "run-#{index}", model: "Source")
          20.times do |record_id|
            stream.validation_message(record_id: record_id, record_type: :source, findings: [{ category: "validation_error", tag: "245", subtag: "a", message: "#{index}-#{record_id}" }])
          end
          exit! 0
        end
      end
      worker_pids.each { |pid| Process.wait(pid) }

      events = File.readlines(loki_path).map { |line| JSON.parse(line) }
      assert_equal 40, events.length
      assert events.all? { |event| event.fetch("event") == "validation_message" }
    end
  end
end
