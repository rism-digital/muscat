require 'progress_bar'
require 'ruby_tindex'
include RDF

SOURCES_URI = "http://muscat.rism.info/sources/"
INCIPIT_URI = "http://muscat.rism.info/incipits/"

GND = RDF::Vocabulary.new("https://d-nb.info/standards/elementset/gnd/")
FOAF = RDF::Vocabulary.new("http://xmlns.com/foaf/0.1/")
MO = RDF::Vocabulary.new("http://purl.org/ontology/mo/")
PAE = RDF::Vocabulary.new("https://www.iaml.info/plaine-easie-code/")
MREL = RDF::Vocabulary.new("http://id.loc.gov/vocabulary/relators/")

#graph = RDF::Graph.new
data = RDF::Vocabulary.new(SOURCES_URI)
data_incipit = RDF::Vocabulary.new(INCIPIT_URI)

codes2relation = {
    arr: MREL.arr,
    asn: MREL.asn,
    aut: MREL.aut,
    ctb: MREL.ctb,
    cmp: MREL.cmp,
    ccp: MREL.ccp,
    cur: MREL.cur,
    scr: MREL.scr,
    dte: MREL.dte,
    dst: MREL.dst,
    edt: MREL.edt,
    egr: MREL.egr,
    fmo: MREL.fmo,
    ill: MREL.ill,
    lbt: MREL.lbt,
    ltg: MREL.ltg,
    oth: MREL.oth,
    prf: MREL.prf,
    prt: MREL.prt,
    pbl: MREL.pbl,
    lyr: MREL.lyr,
    trl: MREL.trl,
    dub: MREL.dub,
}

begin_time = Time.now

PREFIXES = {
  gnd: GND.to_uri,
  dc: RDF::Vocab::DC.to_uri,
  dc11: RDF::Vocab::DC11.to_uri,
  mo: MO.to_uri,
  foaf: FOAF.to_uri,
  pae: PAE.to_uri
}

#RDF::Writer.open("rism.ttl", format: :ttl) do |writer|
File.open("rism.ttl", 'w') do |writer|
#    writer.prefixes = PREFIXES

    @parallel_jobs = 10
    @all_src = Source.all.count
    @limit = @all_src / @parallel_jobs

    #pb = ProgressBar.new(Source.count)
    #Source.find_in_batches do |batch|
    #    batch.each do |sid|

    results = Parallel.map(0..@parallel_jobs, in_processes: @parallel_jobs, progress: "Saving sources") do |jobid|
        offset = @limit * jobid

        Source.order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
            s = Source.find(sid.id)

            graph = RDF::Graph.new
            s.marc.load_source false

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

            # Now do the incipits
            s.marc.each_by_tag("031") do |t|

                subtags = [:a, :b, :c, :d, :g, :n, :o, :p, :m, :t, :e, :r, :q, :z]
                vals = {}

                subtags.each do |st|
                  v = t.fetch_first_by_tag(st)
                  vals[st] = v && v.content ? v.content.strip : "0"
                end

                next if vals[:p] == "0"

                incipit_id = "#{s.id}-#{vals[:a].to_i.to_s}.#{vals[:b].to_i.to_s}.#{vals[:c].to_i.to_s}".strip
                incipit_uri = INCIPIT_URI + incipit_id

                graph << [data_incipit[incipit_id], RDF::Vocab::DC.identifier, incipit_id]
                graph << [data_incipit[incipit_id], PAE.incipit, vals[:p]]

                graph << [data_incipit[incipit_id], PAE.role, vals[:e]]         if vals[:e] != 0
                graph << [data_incipit[incipit_id], PAE.text, vals[:t]]         if vals[:t] != 0
                graph << [data_incipit[incipit_id], PAE.keyOrMode, vals[:r]]    if vals[:r] != 0
                graph << [data_incipit[incipit_id], PAE.keysig, vals[:n]]       if vals[:n] != 0
                graph << [data_incipit[incipit_id], PAE.timesig, vals[:o]]      if vals[:o] != 0
                graph << [data_incipit[incipit_id], PAE.clef, vals[:g]]         if vals[:g] != 0
                graph << [data_incipit[incipit_id], PAE.description, vals[:q]]  if vals[:q] != 0
                graph << [data_incipit[incipit_id], PAE.scoring, vals[:z]]      if vals[:z] != 0

                graph << [data_incipit[incipit_id], MO.movement_number, vals[:b].to_i.to_s]
                graph << [data_incipit[incipit_id], RDF::Vocab::DC.title, vals[:d]] if vals[:d] != 0
                graph << [data_incipit[incipit_id], RDF::Vocab::DC.isPartOf, data[s.id]]

                # Now add the TINDEX data
                pae = "@start:#{incipit_id}\n";
                pae = pae + "@clef:#{vals[:g]}\n";
                pae = pae + "@keysig:#{vals[:n]}\n";
                pae = pae + "@key:\n";
                pae = pae + "@timesig:#{vals[:o]}\n";
                pae = pae + "@data:#{vals[:p]}\n";
                pae = pae + "@end:#{incipit_id}\n"
                #puts pae

                tindex =  RubyTindex.get_text(pae, incipit_id)
                if tindex && !tindex.empty?
                    #puts tindex.split("\t")
                    ##THIS IS HERE FOR TESTING
                    graph << [data_incipit[incipit_id], PAE.scoring, tindex]
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

            #pb.increment!
            s = nil
            #graphs << graph
            #writer << graph.to_ttl

            out = RDF::Writer.for(:ttl).buffer do |w|
                w.prefixes = PREFIXES
                w << graph
            end
            writer << out
            graph = nil
        end #batch.each
    end #batch
end #writer

puts "Source exporting started at #{begin_time.to_s}, (#{Time.now - begin_time} seconds run time)"

#puts graph.to_ttl(prefixes: {gnd: GND.to_uri})

#w = RDF::Writer.for(:ttl).buffer do |writer|
#RDF::Writer.open("rism.ttl", format: :ttl) do |writer|
    #writer.prefixes = PREFIXES
    #graph.each_statement do |statement|
    #    writer << statement
    #en
#    graphs.each do |graph|
#        writer << graph
#    end
#end
#puts w
