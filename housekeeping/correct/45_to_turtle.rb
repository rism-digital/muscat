require 'progress_bar'
include RDF

SOURCES_URI = "http://muscat.rism.info/sources/"

GND = RDF::Vocabulary.new("https://d-nb.info/standards/elementset/gnd/")
FAAF = RDF::Vocabulary.new("http://xmlns.com/foaf/0.1/")
MO = RDF::Vocabulary.new("http://purl.org/ontology/mo/")

graph = RDF::Graph.new
data = RDF::Vocabulary.new(SOURCES_URI)


codes2relation = {
    arr: GND.arranger,
    asn: RDF::Vocab::DC11.contributor,
    aut: GND.author,
    ctb: RDF::Vocab::DC11.contributor,
    cmp: RDF::Vocab::DC11.contributor,
    ccp: RDF::Vocab::DC11.contributor,
    cur: GND.curator,
    scr: GND.copist,
    dte: GND.dedicatee,
    dst: RDF::Vocab::DC11.contributor,
    edt: GND.editor,
    egr: GND.engraver,
    fmo: GND.formerOwner,
    ill: GND.illustratorOrIlluminator,
    lbt: GND.librettist,
    lgt: GND.lithographer,
    oth: RDF::Vocab::DC11.contributor,
    prf: RDF::Vocab::DC11.contributor,
    prt: GND.printer,
    pbl: RDF::Vocab::DC11.contributor,
    lyr: RDF::Vocab::DC11.contributor,
    trl: GND.translator,
    dub: RDF::Vocab::DC11.contributor,
}

pb = ProgressBar.new(Source.count)
Source.find_in_batches do |batch|
    batch.each do |s|

        uri = "#{s.id}"

        graph << [data[uri], RDF::Vocab::DC.title, s.std_title]
        graph << [data[uri], RDF::Vocab::DC11.creator, s.composer]
        graph << [data[uri], RDF::Vocab::DC.identifier, s.id]

        #there should be just 1...
        s.marc.each_by_tag("240") do |t|
            scoring = t.fetch_first_by_tag("m")
            graph << [data[uri], MO.arrangement_of, scoring.content] if scoring && scoring.content

            key = t.fetch_first_by_tag("r")
            graph << [data[uri], MO.key, key.content] if key && key.content
        end

        s.marc.each_by_tag("700") do |t|
            name = t.fetch_first_by_tag("a")
            code = t.fetch_first_by_tag("4")
            if name && name.content
                if code && code.content
                    if !codes2relation.include?(code.content.to_sym)
                        ap code.content
                        next
                    end
                    graph << [data[uri], codes2relation[code.content.to_sym], name.content]
                else
                    graph << [data[uri], RDF::Vocab::DC11.contributor, name.content]
                end
            end
        end

        s.marc.each_by_tag("500") do |t|
            name = t.fetch_first_by_tag("a").content
            graph << [data[uri], RDF::Vocab::DC11.description, name]
        end

        s.marc.each_by_tag("650") do |t|
            name = t.fetch_first_by_tag("a").content
            graph << [data[uri], RDF::Vocab::DC.subject, name]
        end

        s.marc.each_by_tag("300") do |t|
            t.each_by_tag("a") do |st|
                graph << [data[uri], RDF::Vocab::DC.extent, st.content]
            end

            t.each_by_tag("c") do |st|
                graph << [data[uri], RDF::Vocab::DC.format, st.content]
            end
        end

        # in a collection
        if s.source_id
            graph << [data[uri], RDF::Vocab::DC.isPartOf, data[s.source_id]]
        end

        # a collection
        s.marc.each_by_tag("774") do |t|
            t.each_by_tag("w") do |st|
                graph << [data[uri], RDF::Vocab::DC.hasPart, data[st.content]]
            end
        end

        graph << [data[uri], RDF::Vocab::DC.issued, s.date_from] if s.date_from
        graph << [data[uri], RDF::Vocab::DC.issued, s.date_to] if !s.date_from && s.date_to

        pb.increment!
    end
end

#puts graph.to_ttl(prefixes: {gnd: GND.to_uri})

PREFIXES = {
  gnd: GND.to_uri,
  dc: RDF::Vocab::DC.to_uri,
  dc11: RDF::Vocab::DC11.to_uri,
  mo: MO.to_uri,
  faaf: FAAF.to_uri
}

#w = RDF::Writer.for(:ttl).buffer do |writer|
RDF::Writer.open("rism.ttl", format: :ttl) do |writer|
    writer.prefixes = PREFIXES
    graph.each_statement do |statement|
      writer << statement
    end
end

#puts w
