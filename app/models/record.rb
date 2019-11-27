class Record < ActiveModelSerializers::Model

  attributes :id, :record_type, :marc, :model, :record_status, :record_owner

  def initialize(model, id)
    record = model.capitalize.constantize.find(id) rescue nil
    if record
      @marc = record.marc.to_json
      @id = id
      @record_type = record.record_type rescue nil
      @model = model
      @record_status = record.wf_stage
      @record_owner = record.wf_owner
    end
  end

  def self.search(model, params)
    klass = model.capitalize.constantize
    solr_result = Sunspot.search(klass) do
      fulltext params["query"]
      adjust_solr_params do |par|
        par[:start] = (params["start"]).to_i
        par[:rows] = 10
      end
      with(:wf_stage).equal_to("published") if klass==Source
      order_by(:id, :asc)
    end
    res = []
    solr_result.results.pluck(:id).each do |r|
      res << Record.new(model, r)
    end
    return res
  end

  def update(marc)
    klass = "Marc#{model.capitalize}".constantize
    new_marc = klass.new
    hash = JSON.parse marc.to_json
    new_marc.load_from_hash(hash, User.find(@record_owner))
    item = model.capitalize.constantize.find(id)
    item.marc = new_marc
    item.record_type = @record_type if (item.respond_to? :record_type)
    item.save
  end

end
