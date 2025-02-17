class MarcGndWork < Marc
  def initialize(source = nil, model = "gnd_work")
    super(model, source)
  end

  def to_external(created_at = nil, updated_at = nil, versions = nil, holdings = false, deprecated_ids = true)
    super(created_at, updated_at, nil, holdings)

    leader = "00000cz  a2200000oc 4500"
    # Is this a new record?
    leader = "00000nz  a2200000oc 4500" if get_id() == "__TEMP__"

    new_leader = MarcNode.new("gnd_work", "000", leader, "")
    @root.children.insert(get_insert_position("000"), new_leader)

  end
  
end
