require 'ruby_tindex'

class RdfIncipitExporter
    PAE = RDF::Vocabulary.new("https://www.iaml.info/plaine-easie-code/")
    THFDR = RDF::Vocabulary.new("http://www.themefinder.org/help/")
    MO = RDF::Vocabulary.new("http://purl.org/ontology/mo/")

    PREFIXES = {pae: PAE.to_uri, thfdr: THFDR.to_uri, mo: MO.to_uri,}

    def initialize(graph, data, uri, source_uri)
        @graph = graph
        @data = data
        @uri = uri
        @source_uri = source_uri
        @data_incipit = RDF::Vocabulary.new(@uri)
    end

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

    def export_incipits(t, source)
        subtags = [:a, :b, :c, :d, :g, :n, :o, :p, :m, :t, :e, :r, :q, :z]
            vals = {}

            subtags.each do |st|
                v = t.fetch_first_by_tag(st)
                vals[st] = v && v.content ? v.content.strip : "0"
            end

            return if vals[:p] == "0"

            incipit_id = "#{source.id}-#{vals[:a].to_i.to_s}.#{vals[:b].to_i.to_s}.#{vals[:c].to_i.to_s}".strip
            incipit_uri = @uri + incipit_id

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
            @graph << [@data_incipit[incipit_id], RDF::Vocab::DC.isPartOf, @data[source.id]]

            # Also add the incipit to the source
            ## FIXME move to parent!
            @graph << [@data[@source_uri], RDF::Vocab::DC.hasPart, @data_incipit[incipit_id]]

            #Now do thindex
            incipit_tindex(vals, incipit_id)
    end

    def get_incipit_prefixes
        PREFIXES
    end
end