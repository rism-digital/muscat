require "rails_helper"

RSpec.describe Triggers do
  let(:dispatcher) { Object.new.extend(described_class) }
  let(:person) { Person.new(id: 123) }

  def dispatch(payload, object = person)
    dispatcher.execute_triggers_from_params({ triggers: payload.to_json }, object)
  end

  it "enqueues configured authority saves and deduplicates requested relations" do
    expect(Delayed::Job).to receive(:enqueue).once do |job|
      expect(job).to be_a(SaveItemsJob)
      expect(job.instance_variable_get(:@relation)).to eq("referring_sources")
    end

    dispatch(save: ["referring_sources", "referring_sources"])
  end

  it "rejects destructive methods, unconfigured associations and trigger actions" do
    expect(Delayed::Job).not_to receive(:enqueue)
    dispatch(save: ["delete", "destroy!", "user"], reindex: ["referring_sources"], delete: ["referring_sources"])
  end

  [nil, "{", "null", "[]", '"save"', '{"save":"delete"}', '{"save":[null,1,{}]}'].each do |payload|
    it "ignores malformed or invalid triggers #{payload.inspect}" do
      expect(Delayed::Job).not_to receive(:enqueue)
      dispatcher.execute_triggers_from_params({ triggers: payload }, person)
    end
  end

  it "honors a server-configured reindex trigger for a collection association" do
    profile = instance_double(EditorConfiguration, relation_triggers: { "reindex" => ["referring_sources"] })
    allow(EditorConfiguration).to receive(:get_default_layout).with(person).and_return(profile)
    expect(Delayed::Job).to receive(:enqueue).with(an_instance_of(ReindexItemsJob))
    dispatch(reindex: ["referring_sources"])
  end

  it "does not enqueue triggers when the model has no editor configuration" do
    allow(EditorConfiguration).to receive(:get_default_layout).with(person).and_return(nil)
    expect(Delayed::Job).not_to receive(:enqueue)
    dispatch(save: ["referring_sources"])
  end
end
