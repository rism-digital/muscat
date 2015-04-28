module Muscat
  module Blacklight
    
    module MarcXML
      def self.extended(document)
        document.will_export_as(:marcxml, "application/marcxml+xml")
      end

      def export_as_marcxml 
        model, db_id = id.to_s.split(" ")
        klass = Kernel.const_get(model)
        
        if klass.method_defined? :to_marcxml
          db_doc = klass.send("find", db_id)
          db_doc.to_marcxml
        end
        
      end
      
    end
    
  end
end
