include RDF

GND = RDF::Vocabulary.new("https://d-nb.info/standards/elementset/gnd/")

graph = RDF::Graph.new
data = RDF::Vocabulary.new("http://muscat.rism.info/sources/")


codes2relation = {
    arr: RDF::Vocab::DC11.contributor,
    aut: RDF::Vocab::DC11.contributor,
    ctb: RDF::Vocab::DC11.contributor,
    cmp: RDF::Vocab::DC11.contributor,
    ccp: RDF::Vocab::DC11.contributor,
    scr: RDF::Vocab::DC11.contributor,
    dte: RDF::Vocab::DC11.contributor,
    dst: RDF::Vocab::DC11.contributor,
    edt: RDF::Vocab::DC11.contributor,
    egr: RDF::Vocab::DC11.contributor,
    fmo: GND.formerOwner,
    ill: RDF::Vocab::DC11.contributor,
    ibt: RDF::Vocab::DC11.contributor,
    lgt: RDF::Vocab::DC11.contributor,
    oth: RDF::Vocab::DC11.contributor,
    prf: RDF::Vocab::DC11.contributor,
    prt: RDF::Vocab::DC11.contributor,
    pbl: RDF::Vocab::DC11.contributor,
    lyr: RDF::Vocab::DC11.contributor,
    trl: RDF::Vocab::DC11.contributor,
    dub: RDF::Vocab::DC11.contributor,
}

Source.limit(1000).each do |s|

    uri = "#{s.id}"

    graph << [data[uri], RDF::Vocab::DC.title, s.std_title]
    graph << [data[uri], RDF::Vocab::DC11.creator, s.composer]
    graph << [data[uri], RDF::Vocab::DC.identifier, s.id]

    s.marc.each_by_tag("700") do |t|
        name = t.fetch_first_by_tag("a").content
        code = t.fetch_first_by_tag("4").content
        graph << [data[uri], codes2relation[code.to_sym], name]
    end

    s.marc.each_by_tag("500") do |t|
        name = t.fetch_first_by_tag("a").content
        graph << [data[uri], RDF::Vocab::DC11::description, name]
    end


    s.marc.each_by_tag("650") do |t|
        name = t.fetch_first_by_tag("a").content
        graph << [data[uri], RDF::Vocab::DC::subject, name]
    end

end

puts graph.to_turtle