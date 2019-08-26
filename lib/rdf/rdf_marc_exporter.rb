require 'rdf/rdf_incipit_exporter.rb'
include RDF

class RdfMarcExporter

    def initialize(source, configuration)
        @source = source
        @configuration = configuration
        @incipit_exporter = nil

        @data = RDF::Vocabulary.new(@configuration.uri)

        @graph = RDF::Graph.new

        @uri = "#{source.id}"

        # Export incipits?
        if @configuration.marc_incipit_tag
            throw "No Incipit URI" if !@configuration.incipit_uri
            @incipit_exporter = RdfIncipitExporter.new(@graph, @data, @configuration.incipit_uri, @uri)
        end
    end

    def create_marc_incipits
        return if !@configuration.marc_incipit_tag

        @source.marc.each_by_tag(@configuration.marc_incipit_tag) do |t|
            @incipit_exporter.export_incipits(t, @source)
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
        create_marc_incipits

        prefixes = @configuration.prefixes
        if @configuration.marc_incipit_tag
            prefixes.merge!(@incipit_exporter.get_incipit_prefixes)
        end

        out = RDF::Writer.for(:ttl).buffer do |w|
            w.prefixes = prefixes
            w << @graph
        end
        return out

    end

end