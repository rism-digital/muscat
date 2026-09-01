ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __dir__)
require Rails.root.join("lib", "muscat_checkup")

RSpec.describe MuscatCheckupResult do
  it "exposes the complete checkup result" do
    result = described_class.new(
      errors: { 1 => "failed" },
      validations: { 1 => { "100" => {} } },
      foreign_tag_errors: ["100a old val"],
      unknown_tags: { "999-a" => { count: 1, items: [1] } },
      observations: { records_scanned: 1 }
    )

    expect(result.errors).to eq(1 => "failed")
    expect(result.validations).to eq(1 => { "100" => {} })
    expect(result.foreign_tag_errors).to eq(["100a old val"])
    expect(result.unknown_tags).to eq("999-a" => { count: 1, items: [1] })
    expect(result.observations).to eq(records_scanned: 1)
  end
end

RSpec.describe RecordCheckupResult do
  it "exposes one record's errors, validations, and findings" do
    result = described_class.new(
      errors: { 1 => "failed" },
      validations: { 1 => { "100" => {} } },
      findings: [{ category: "validation_error" }]
    )

    expect(result.errors).to eq(1 => "failed")
    expect(result.validations).to eq(1 => { "100" => {} })
    expect(result.findings).to eq([{ category: "validation_error" }])
  end
end

RSpec.describe MuscatCheckup do
  it "returns a consistent result when telemetry is disabled" do
    model = Class.new do
      def self.count
        0
      end
    end
    folder = Struct.new(:folder_items).new([])

    result = described_class.new(model: model, folder: folder).validate_parallel

    expect(result).to be_a(MuscatCheckupResult)
    expect(result.errors).to eq({})
    expect(result.validations).to eq({})
    expect(result.foreign_tag_errors).to eq([])
    expect(result.unknown_tags).to eq({})
    expect(result.observations).to eq(
      records_scanned: 0,
      records_with_findings: 0,
      findings: {}
    )
  end
end

RSpec.describe TelemetryNullWorker do
  subject(:worker) { described_class.new(nil) }

  it "implements telemetry operations without collecting anything" do
    worker.record(double("record"), [{ category: "validation_error" }])

    expect(worker).not_to be_collect_findings
    expect(worker.technical_findings(output: "error", exception: StandardError.new("failed"), phase: :validate)).to eq([])
    expect(worker.observations).to eq(
      records_scanned: 0,
      records_with_findings: 0,
      findings: {}
    )
  end
end

RSpec.describe TelemetryWorker do
  subject(:worker) { described_class.new(observability) }

  let(:event_stream) { instance_double(ValidationObservability::EventStream) }
  let(:observability) do
    {
      loki_log: "/tmp/validation.jsonl",
      run_id: "run-id",
      model: "Source"
    }
  end
  let(:record) do
    Struct.new(:id) do
      def get_record_type
        :manuscript
      end
    end.new(42)
  end

  before do
    allow(ValidationObservability::EventStream).to receive(:new).and_return(event_stream)
  end

  it "streams findings and updates its observations" do
    findings = [{ tag: "100", subtag: "a", message: "Invalid", category: "validation_error" }]
    emitted_event = nil

    allow(event_stream).to receive(:validation_message) do |event|
      emitted_event = event
    end

    worker.record(record, findings)

    expect(emitted_event).to eq(
      record_id: 42,
      record_type: "manuscript",
      findings: findings
    )
    expect(worker).to be_collect_findings
    expect(worker.observations).to eq(
      records_scanned: 1,
      records_with_findings: 1,
      findings: { ["manuscript", "validation_error"] => 1 }
    )
  end

  it "counts clean records without writing an event" do
    expect(event_stream).not_to receive(:validation_message)

    worker.record(record, [])

    expect(worker.observations).to include(records_scanned: 1, records_with_findings: 0)
  end

  it "turns captured output and exceptions into technical findings" do
    exception = StandardError.new("validation failed")

    expect(worker.technical_findings(output: "diagnostic", exception: exception, phase: :validate)).to eq(
      [
        {
          tag: "no_tag",
          subtag: "no_subtag",
          message: "diagnostic",
          category: "record_exception_validate"
        },
        {
          tag: "no_tag",
          subtag: "no_subtag",
          message: "validation failed",
          category: "record_exception_validate"
        }
      ]
    )
  end
end
