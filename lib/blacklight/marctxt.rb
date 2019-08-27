module Muscat
    module Blacklight

        module MarcTXT
            def self.extended(document)
              document.will_export_as(:txt, "text/plain")
            end
        
            def export_as_txt
              model, db_id = id.to_s.split(" ")
              klass = Kernel.const_get(model)
              
              if klass.method_defined? :marc
                db_doc = klass.send("find", db_id)
                db_doc.marc.to_marc
              end
              
            end
            
        end
        

    end
end