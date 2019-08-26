require 'rdf/rdf_marc_exporter'
include RDF

class RdfExporter

    attr_reader :marc_mappings
    attr_reader :field_mappings
    attr_reader :link_mappings
    attr_reader :marc_link_mappings
    attr_reader :prefixes

    def initialize(model)
        @prefixes = Hash.new
        @marc_mappings = []
        @field_mappings = []
        @link_mappings = []
        @marc_link_mappings = []

        @model = model
    end
    
    def add_prefix(name, url)
        throw "Duplicate prefix #{name}" if (@prefixes.keys && @prefixes.keys.include?(name))

        prefix = RDF::Vocabulary.new(url)
        @prefixes[name] = prefix
    end

    def add_marc_mapping(marc_tag, marc_subtag, prefix, predicate)
        throw "Undeclared prefix #{prefix}" if !@prefixes.keys.include?(prefix)

        @marc_mappings << {
            tag: marc_tag,
            subtag: marc_subtag,
            prefix: @prefixes[prefix],
            predicate: predicate
        }

    end

    def add_marc_link_mapping(marc_tag, marc_subtag, prefix, predicate)
        throw "Undeclared prefix #{prefix}" if !@prefixes.keys.include?(prefix)

        @marc_link_mappings << {
            tag: marc_tag,
            subtag: marc_subtag,
            prefix: @prefixes[prefix],
            predicate: predicate
        }

    end

    def add_record_mapping(field, prefix, predicate)
        throw "Undeclared prefix #{prefix}" if !@prefixes.keys.include?(prefix)

        @field_mappings << {
            field: field,
            prefix: @prefixes[prefix],
            predicate: predicate
        }
    end

    def add_link_mapping(field, prefix, predicate)
        throw "Undeclared prefix #{prefix}" if !@prefixes.keys.include?(prefix)

        @link_mappings << {
            field: field,
            prefix: @prefixes[prefix],
            predicate: predicate
        }
    end

    def export_one(source_id)
        ex = RdfMarcExporter.new(source_id, self)
        ex.export
    end

end
