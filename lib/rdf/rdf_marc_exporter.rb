require 'ruby_tindex'
include RDF

class RdfMarcExporter

    def initialize(source, configuration)
        @source = source
        @configuration = configuration

        @data = RDF::Vocabulary.new(SOURCES_URI)
        @data_incipit = RDF::Vocabulary.new(INCIPIT_URI)

        @graph = RDF::Graph.new

        @uri = "#{source.id}"
    end

    SOURCES_URI = "http://demo.muscat-project.org/sources/"
    INCIPIT_URI = "http://demo.muscat-project.org/incipits/"

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

        # Now do the incipits
        @source.marc.each_by_tag("031") do |t|
            export_incipits(t)
        end
    end

    def create_record_fields
        @configuration.field_mappings.each do |mapping|
            next if !@source[mapping[:field]]
            @graph << [@data[@uri], mapping[:prefix][mapping[:predicate]], @source[mapping[:field]]]
        end
    end

    def create_record_links
        @configuration.link_mappings.each do |mapping|
            next if !@source[mapping[:field]]
            @graph << [@data[@uri], mapping[:prefix][mapping[:predicate]], @data[@source[mapping[:field]]]]
        end
    end

    def create_marc_fields
        @configuration.marc_mappings.each do |mapping|
            @source.marc.each_by_tag(mapping[:tag]) do |t|
                t.each_by_tag(mapping[:subtag]) do |st|
                    next if !st || !st.content
                    @graph << [@data[@uri], mapping[:prefix][mapping[:predicate]], st.content]
                end
            end
        end
    end

    def create_marc_coded_fields
        @configuration.marc_coded_field_mappings.each do |mapping|
            @source.marc.each_by_tag(mapping[:tag]) do |t|
                data_tag = t.fetch_first_by_tag(mapping[:subtag])
                next if !data_tag || !data_tag.content
                
                t.each_by_tag(mapping[:code_subtag]) do |stc|
                    next if !stc || !stc.content

                    if @configuration.marc_code_mappings.include?(stc.content.to_sym)
                        @graph << [@data[@uri], @configuration.marc_code_mappings[stc.content.to_sym], data_tag.content]
                    else
                        puts "Unknown code #{stc.content}"
                    end
                end
            end
        end
    end

    def create_link_fields
        @configuration.marc_link_mappings.each do |mapping|
            @source.marc.each_by_tag(mapping[:tag]) do |t|
                t.each_by_tag(mapping[:subtag]) do |st|
                    next if !st || !st.content
                    @graph << [@data[@uri], mapping[:prefix][mapping[:predicate]], @data[st.content]]
                end
            end
        end
    end

    def export
        
        create_record_fields
        create_marc_fields
        create_marc_coded_fields
        create_link_fields
        create_record_links

        out = RDF::Writer.for(:ttl).buffer do |w|
            w.prefixes = @configuration.prefixes
            w << @graph
        end
        return out

    end

end