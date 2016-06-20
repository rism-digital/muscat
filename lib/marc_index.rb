module MarcIndex
  
  def self.attach_marc_index(sunspot_dsl, klass)
    
    IndexConfig.get_fields(klass).each do |conf_tag, properties|
      
      # index_processor: mash togeather the values of one or more tags/subtags
      index_processor_helper = properties && properties.has_key?(:index_processor_helper) ? properties[:index_processor_helper] : nil
      
      store = properties && properties.has_key?(:store) ? properties[:store] : false
      boost = properties && properties.has_key?(:boost) ? properties[:boost] : 1.0
      type =  properties && properties.has_key?(:type) ? properties[:type] : 'text'
      
      # Build up our options for the sunxpot index call
      opts = {:stored => store}
      # Dumb convention of the week winner:
      # text (i.e. fulltext) items are multiple by default
      # so if you pass the :multiple option it will
      # raise an error telling you it is unsupported
      # (ignoring it was too difficult? maybe print a warn?)
      opts[:multiple] = true if type != 'text'
      
      if properties && properties.has_key?(:as)
        opts[:as] = properties[:as]
      end

      sunspot_dsl.send(type, conf_tag, opts) do
        if index_processor_helper
          marc.send(index_processor_helper, conf_tag, properties, marc, self)
        else
          ####marc_index_tag(tag, properties, marc, self)
          
          ## NOTE NOTE NOTE
          ## THIS USED TO BE A SEPARATE FUNCTION
          # Since this code is executed deferred in the sunspot context
          # calling it asa function slows down
          # When this was a class method it would slow down 10 fold
          # It is not nice but written out inline is the most efficent way
          
          # index_helper: fetch a subtag and process the value
          index_helper = properties && properties.has_key?(:index_helper) ? properties[:index_helper] : nil
          # missing helper: if the tag is not present still provide a default value
          missing_helper = properties && properties.has_key?(:missing_helper) ? properties[:missing_helper] : nil
          # tags can be spefied if the field name it not the tag name
          tag = properties && properties.has_key?(:from_tag) ? properties[:from_tag] : nil
          subtag = properties && properties.has_key?(:from_subtag) ? properties[:from_subtag] : nil
        
          out = []
          
          # Get the 852 from holding records. It checks for a
          # configuration item :holding_record in the index config
          # Only for sources with no 852 (i.e. prints)
          if self.is_a? Source
            if properties && properties.has_key?(:holding_record)
              # If the 852 tag is present do not duplicate it
              if marc.by_tags("852").count == 0

                self.holdings.each do |h|
                  puts "HOLDING #{h.id}"
                  begin
                    holding_marc = h.marc
                    holding_marc.load_source false
                  rescue => e
                    $stderr.puts "Index: Could not load holding record #{h.id} (ref. from #{self.id})"
                    $stderr.puts e.message.blue
                    next
                  end

                  holding_marc.each_by_tag("852") do |t|
                    new_852 = t.deep_copy
                    marc.root.children.insert(marc.get_insert_position("852"), new_852)
                  end

                end # holdings.each
              end # count == 0
            end # properties has
          end #is_a? Source

          if !tag
            # By convention the first three digits
            tag = conf_tag[0..2]
      
            # If not a conrol field
            if conf_tag.length == 4
              subtag = conf_tag[3]
            end
          end
    
          begin
            tags = marc.by_tags(tag)

            if tags.count == 0
              if missing_helper && self.respond_to?(missing_helper)
                out << self.send(missing_helper)
              end
            else
              tags.each do |marctag|
                if subtag
                  marctag.each_by_tag(subtag) do |marcvalue|
                    next if !marcvalue.content
                    value = index_helper != nil ? marc.send(index_helper, marcvalue.content) : marcvalue.content
                    out << value
                  end
                else
                  # No subtag, is it a control field.
                  next if !marctag.content
                  value = index_helper != nil ? marc.send(index_helper, marctag.content) : marctag.content
                  out << value
                end
              end
            end

          rescue => e
            $stderr.puts "MarcIndex: Marc failed to load for ".red +  self[:id].to_s.magenta
            $stderr.puts "While indexing: #{conf_tag.to_s.green}, #{subtag.to_s.yellow}"
            $stderr.puts "Look for the MARC error, as the index tag could have triggered a marc reload and is unrelated"
            $stderr.puts e.exception.to_s.blue
            $stderr.puts
          end
          ## Return the value
          out
          ## END INLINED FUNCTION
        end # index_processor_helper
      end #sunspot_dsl.send
    end #IndexConfig.get_fields
  end

=begin
  def self.marc_index_tag(conf_tag, conf_properties, marc, model)
    
    # index_helper: fetch a subtag and process the value
    index_helper = conf_properties && conf_properties.has_key?(:index_helper) ? conf_properties[:index_helper] : nil
    # missing helper: if the tag is not present still provide a default value
    missing_helper = conf_properties && conf_properties.has_key?(:missing_helper) ? conf_properties[:missing_helper] : nil
    # tags can be spefied if the field name it not the tag name
    tag = conf_properties && conf_properties.has_key?(:from_tag) ? conf_properties[:from_tag] : nil
    subtag = conf_properties && conf_properties.has_key?(:from_subtag) ? conf_properties[:from_subtag] : nil
        
    out = []
    
    if !tag
      # By convention the first three digits
      tag = conf_tag[0..2]
      
      # If not a conrol field
      if conf_tag.length == 4
        subtag = conf_tag[3]
      end
    end
    
    begin

      tags = marc.by_tags(tag)

      if tags.count == 0
        if missing_helper && model.respond_to?(missing_helper)
          out << model.send(missing_helper)
        end
      else
        tags.each do |marctag|
          if subtag
            marctag.each_by_tag(subtag) do |marcvalue|
              next if !marcvalue.content
              value = index_helper != nil ? marc.send(index_helper, marcvalue.content) : marcvalue.content
              out << value
            end
          else
            # No subtag, is it a control field.
            next if !marctag.content
            value = index_helper != nil ? marc.send(index_helper, marctag.content) : marctag.content
            out << value
          end
        end
      end

    rescue => e
      puts e.exception
      puts "Marc failed to load for #{model.to_yaml}, check foreign relations, data: #{conf_tag}, #{subtag}"
    end

    return out
    
  end
=end
  
end
