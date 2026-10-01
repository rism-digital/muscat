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

RSpec.describe MuscatCheckup do
  it "returns a consistent result when telemetry is disabled" do
    model = Class.new do
      def self.count
        0
      end
    end
    folder = Struct.new(:folder_items).new([])

    expect(TelemetryNullWorker).to receive(:new).and_call_original
    expect(TelemetryWorker).not_to receive(:new)
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

  it "does not collect findings for a normal record validation" do
    model = Class.new do
      def self.count
        0
      end
    end
    record = Struct.new(:id).new(42)
    checkup = described_class.new(model: model)
    validation = { "100" => { "a" => ["Invalid"] } }
    validator = instance_double(MarcValidator, get_errors: validation)
    telemetry = TelemetryNullWorker.new

    allow(checkup).to receive(:validate_record).and_return(validator)
    expect(validator).not_to receive(:get_findings)

    expect(checkup.send(:load_and_validate_item, record, telemetry, false)).to eq([{}, { 42 => validation }])
  end
end

RSpec.describe TelemetryNullWorker do
  subject(:worker) { described_class.new(nil) }

  it "implements telemetry operations without collecting anything" do
    worker.record(double("record"), double("validator"), "error", StandardError.new("failed"), :validate)

    expect(worker).not_to be_collect_findings
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
    validator = instance_double(MarcValidator, get_findings: findings)
    emitted_event = nil

    allow(event_stream).to receive(:validation_message) do |event|
      emitted_event = event
    end

    worker.record(record, validator, "", nil, :validate)

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
    validator = instance_double(MarcValidator, get_findings: [])
    expect(event_stream).not_to receive(:validation_message)

    worker.record(record, validator, "", nil, :validate)

    expect(worker.observations).to include(records_scanned: 1, records_with_findings: 0)
  end

  it "turns captured output and exceptions into technical findings" do
    exception = StandardError.new("validation failed")
    emitted_event = nil

    allow(event_stream).to receive(:validation_message) do |event|
      emitted_event = event
    end

    worker.record(record, nil, "diagnostic", exception, :validate)

    expect(emitted_event[:findings]).to eq(
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
