require 'ruby_tindex'
include RDF

class RdfSourceExport

    SOURCES_URI = "http://demo.muscat-project.org/sources/"
    INCIPIT_URI = "http://demo.muscat-project.org/incipits/"

    GND = RDF::Vocabulary.new("https://d-nb.info/standards/elementset/gnd/")
    FOAF = RDF::Vocabulary.new("http://xmlns.com/foaf/0.1/")
    MO = RDF::Vocabulary.new("http://purl.org/ontology/mo/")
    PAE = RDF::Vocabulary.new("https://www.iaml.info/plaine-easie-code/")
    MREL = RDF::Vocabulary.new("http://id.loc.gov/vocabulary/relators/")
    THFDR = RDF::Vocabulary.new("http://www.themefinder.org/help/")

    CODES2RELATION = {
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
    pae: PAE.to_uri,
    thfdr: THFDR.to_uri
    }

    def incipit_tindex(vals, incipit_id)
        # Now add the TINDEX @data
        pae = "@start:#{incipit_id}\n";
        pae = pae + "@clef:#{vals[:g]}\n";
        pae = pae + "@keysig:#{vals[:n]}\n";
        pae = pae + "@key:\n";
        pae = pae + "@timesig:#{vals[:o]}\n";
        pae = pae + "@data:#{vals[:p]}\n";
        pae = pae + "@end:#{incipit_id}\n"

        tindex =  RubyTindex.get_text(pae, "unused")
        return if !tindex || tindex.empty?

        tindex.split("\t").each do |idx|
            next if idx.include?("unused")
            next if idx.include?("ZC=")

            type = THFDR.unknown

            if idx[0] == '@'
                type = THFDR.opt1
            elsif idx[0] =='#'
                type = THFDR.opt2
            elsif idx[0] =='{'
                type = THFDR.opt3
            elsif idx[0] =='~'
                type = THFDR.opt4
            elsif idx[0] =='`'
                type = THFDR.opt5
            elsif idx[0] =='%'
                type = THFDR.opt6
            elsif idx[0] =='M'
                type = THFDR.opt7
            elsif idx[0] =='J'
                type = THFDR.opt8
            elsif idx[0] =='j'  
                type = THFDR.opt9  
            elsif idx[0] =='='
                type = THFDR.opt10
            elsif idx[0] ==':'
                type = THFDR.opt11
            elsif idx[0] ==';'
                type = THFDR.opt12
            elsif idx[0] =='\''
                type = THFDR.opt13
            elsif idx[0] =='}'
                type = THFDR.opt14
            elsif idx[0] =='&'
                type = THFDR.opt15
            elsif idx[0] =='^'
                type = THFDR.opt16
            else
                puts "Unsecognized start #{idx[0]}".red
            end
            
            @graph << [@data_incipit[incipit_id], type, idx.strip]
        end

    end

    def export_incipits(t)
        subtags = [:a, :b, :c, :d, :g, :n, :o, :p, :m, :t, :e, :r, :q, :z]
            vals = {}

            subtags.each do |st|
                v = t.fetch_first_by_tag(st)
                vals[st] = v && v.content ? v.content.strip : "0"
            end

            return if vals[:p] == "0"

            incipit_id = "#{@source.id}-#{vals[:a].to_i.to_s}.#{vals[:b].to_i.to_s}.#{vals[:c].to_i.to_s}".strip
            incipit_uri = INCIPIT_URI + incipit_id

            @graph << [@data_incipit[incipit_id], RDF::Vocab::DC.identifier, incipit_id]
            @graph << [@data_incipit[incipit_id], PAE.incipit, vals[:p]]

            @graph << [@data_incipit[incipit_id], PAE.role, vals[:e]]         if vals[:e] != 0
            @graph << [@data_incipit[incipit_id], PAE.text, vals[:t]]         if vals[:t] != 0
            @graph << [@data_incipit[incipit_id], PAE.keyOrMode, vals[:r]]    if vals[:r] != 0
            @graph << [@data_incipit[incipit_id], PAE.keysig, vals[:n]]       if vals[:n] != 0
            @graph << [@data_incipit[incipit_id], PAE.timesig, vals[:o]]      if vals[:o] != 0
            @graph << [@data_incipit[incipit_id], PAE.clef, vals[:g]]         if vals[:g] != 0
            @graph << [@data_incipit[incipit_id], PAE.description, vals[:q]]  if vals[:q] != 0
            @graph << [@data_incipit[incipit_id], PAE.scoring, vals[:z]]      if vals[:z] != 0

            @graph << [@data_incipit[incipit_id], MO.movement_number, vals[:b].to_i.to_s]
            @graph << [@data_incipit[incipit_id], RDF::Vocab::DC.title, vals[:d]] if vals[:d] != 0
            @graph << [@data_incipit[incipit_id], RDF::Vocab::DC.isPartOf, @data[@source.id]]

            # Also add the incipit to the source
            @graph << [@data[@uri], RDF::Vocab::DC.hasPart, @data_incipit[incipit_id]]

            #Now do thindex
            incipit_tindex(vals, incipit_id)
    end

    def export_marc_tags()
        #there should be just 1...
        @source.marc.each_by_tag("240") do |t|
            scoring = t.fetch_first_by_tag("m")
            @graph << [@data[@uri], MO.arrangement_of, scoring.content] if scoring && scoring.content

            key = t.fetch_first_by_tag("r")
            @graph << [@data[@uri], MO.key, key.content] if key && key.content
        end

        @source.marc.each_by_tag("700") do |t|
            name = t.fetch_first_by_tag("a")
            code = t.fetch_first_by_tag("4")
            if name && name.content
                if code && code.content
                    if !CODES2RELATION.include?(code.content.to_sym)
                        ap code.content
                        next
                    end
                    @graph << [@data[@uri], CODES2RELATION[code.content.to_sym], name.content]
                else
                    @graph << [@data[@uri], RDF::Vocab::DC11.contributor, name.content]
                end
            end
        end

        @source.marc.each_by_tag("500") do |t|
            name = t.fetch_first_by_tag("a").content
            @graph << [@data[@uri], RDF::Vocab::DC11.description, name]
        end

        @source.marc.each_by_tag("650") do |t|
            name = t.fetch_first_by_tag("a").content
            @graph << [@data[@uri], RDF::Vocab::DC.subject, name]
        end

        @source.marc.each_by_tag("300") do |t|
            t.each_by_tag("a") do |st|
                @graph << [@data[@uri], RDF::Vocab::DC.extent, st.content]
            end

            t.each_by_tag("c") do |st|
                @graph << [@data[@uri], RDF::Vocab::DC.format, st.content]
            end
        end

        # Now do the incipits
        @source.marc.each_by_tag("031") do |t|
            export_incipits(t)
        end
    end

    def initialize(source)
        @source = source
        @data = RDF::Vocabulary.new(SOURCES_URI)
        @data_incipit = RDF::Vocabulary.new(INCIPIT_URI)

        @graph = RDF::Graph.new

        @uri = "#{source.id}"
    end

    def to_ttl()
        @graph << [@data[@uri], RDF::Vocab::DC.title, @source.std_title]
        @graph << [@data[@uri], RDF::Vocab::DC11.creator, @source.composer]
        @graph << [@data[@uri], RDF::Vocab::DC.identifier, @source.id]

        # Export all the marc tags
        export_marc_tags

        # in a collection
        if @source.source_id
            @graph << [@data[@uri], RDF::Vocab::DC.isPartOf, @data[@source.source_id]]
        end

        # a collection
        @source.marc.each_by_tag("774") do |t|
            t.each_by_tag("w") do |st|
                @graph << [@data[@uri], RDF::Vocab::DC.hasPart, @data[st.content]]
            end
        end

        @graph << [@data[@uri], RDF::Vocab::DC.issued, @source.date_from] if @source.date_from
        @graph << [@data[@uri], RDF::Vocab::DC.issued, @source.date_to] if !@source.date_from && @source.date_to

        out = RDF::Writer.for(:ttl).buffer do |w|
            w.prefixes = PREFIXES
            w << @graph
        end
        return out
    end

end