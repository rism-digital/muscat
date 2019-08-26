require 'rdf/rdf_exporter'

module RdfExportExtension

  def self.included(klass)
    klass.instance_eval do
      attr_reader :exporter

      extend  ClassMethods
      include InstanceMethods
    end
  end

  module ClassMethods
    @@exporter = nil
   
    def rdfable(&block)
      @@exporter = RdfExporter.new(self.class)
      instance_eval(&block)
    end

    def marc_field(tag, subtag, prefix, predicate)
      @@exporter.add_marc_mapping tag, subtag, prefix, predicate
    end

    def marc_field_coded(tag, subtag, subtag_code)
      @@exporter.add_marc_coded_field_mapping tag, subtag, subtag_code
    end

    def marc_field_link(tag, subtag, prefix, predicate)
      @@exporter.add_marc_link_mapping tag, subtag, prefix, predicate
    end

    def field(field, prefix, predicate)
      @@exporter.add_record_mapping field, prefix, predicate
    end

    def link(field, prefix, predicate)
      @@exporter.add_link_mapping field, prefix, predicate
    end

    def code_map(marc_code, prefix, predicate)
      @@exporter.add_code_mapping marc_code, prefix, predicate
    end

    def prefix(name, url)
      @@exporter.add_prefix name, url
    end

    def rdf_exporter
      @@exporter
    end

  end

  module InstanceMethods
      def to_ttl()
        Source::rdf_exporter.export_one(self)
      end
  end

end
