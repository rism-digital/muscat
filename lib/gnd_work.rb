class GndWork < MarcGndWork

  attr_accessor :marc
  attr_accessor :id
  attr_accessor :lock_version
  attr_accessor :marc_source
  #composed_of :marc, :class_name => "MarcGndWork", :mapping => %w(marc_source to_marc)

  def self.wf_stages 
    { inprogress: 0, published: 1 }
  end

  def load_json_marc(json_marc, dry_run)
  end

  # Method: set_object_fields
  # Parameters: none
  # Return: none
  #
  # Brings in the real data into the fields from marc structure
  def set_object_fields
    marc_source_id = marc.get_marc_source_id
    self.id = marc_source_id if marc_source_id and marc_source_id != "__TEMP__"

    self.marc_source = self.marc.to_marc
  end

  def new_record?
    id == nil
  end

end