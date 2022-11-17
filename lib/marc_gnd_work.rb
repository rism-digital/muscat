class MarcGndWork < Marc
  def initialize(source = nil, model = "gnd_work")
    super(model, source)
  end

  def to_external(updated_at = nil, versions = nil, holdings = false)
    super(updated_at, nil, holdings)
    # nothing specific to do - this is used ony for deprecating works
  end
  
end
