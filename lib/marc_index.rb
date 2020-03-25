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

      sunspot_dsl.send(type, conf_tag, opts) do |obj|
        if index_processor_helper
          obj.marc.send(index_processor_helper, conf_tag, properties, obj.marc, obj)
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

          if !tag
            # By convention the first three digits
            tag = conf_tag[0..2]
      
            # If not a conrol field
            if conf_tag.length == 4
              subtag = conf_tag[3]
            end
          end
    
          # Get configured fields for holding records. It checks for a
          # configuration item :holding_record in the index config
          # Only for sources with holdings
          # TODO since this block is called with every configured field we have some considerable overhead
          if obj.is_a? Source
            holdings = []

            # For cild prints, we index the holdings from the parent
            if obj.record_type == MarcSource::RECORD_TYPES[:edition_content]
              if obj.parent_source
                holdings = obj.parent_source.holdings
              else
                # No parent!
                $stderr.puts "Index: Source #{obj.id} is a print child with no parent, cannot index holdings"
              end
            else
              # For all other cases
              holdings = obj.holdings
            end

            if !holdings.empty? && properties && properties.has_key?(:holding_record)
              holdings.each do |holding|
                begin
                  holding_marc = holding.marc
                  holding_marc.load_source false
                  holding_marc.all_values_for_tags_with_subtag(tag, subtag).each do |v|
                    out << v
                  end
                rescue => e
                  $stderr.puts "Index: Could not load holding record #{h.id} (ref. from #{obj.id})"
                  $stderr.puts e.message.blue
                  next
                end
              end
            else
              # Print an error, only for regular Edition parent records
              # Edition child records should not have holdings!
              # This can be checked with mainteaince scripts
              $stderr.puts "Index: Source #{obj.id} (type #{obj.get_record_type}) has no holding records" if !obj.record_type == MarcSource::RECORD_TYPES[:edition_content]
            end
          end

          begin
            tags = obj.marc.by_tags(tag)

            if tags.count == 0
              if missing_helper && obj.respond_to?(missing_helper)
                out << obj.send(missing_helper)
              end
            else
              tags.each do |marctag|
                if subtag
                  marctag.each_by_tag(subtag) do |marcvalue|
                    next if !marcvalue.content
                    value = index_helper != nil ? obj.marc.send(index_helper, marcvalue.content) : marcvalue.content
                    out << value
                  end
                else
                  # No subtag, is it a control field.
                  next if !marctag.content
                  value = index_helper != nil ? obj.marc.send(index_helper, marctag.content) : marctag.content
                  out << value
                end
              end
            end
          rescue => e
            $stderr.puts "MarcIndex: Marc failed to load for ".red +  obj[:id].to_s.magenta
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
