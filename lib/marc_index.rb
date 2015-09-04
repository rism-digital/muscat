class MarcIndex

  def self.attach_marc_index(sunspot_dsl, klass)

    IndexConfig.get_fields(klass).each do |tag, properties|

      # index_processor: mash together the values of one or more tags/subtags
      index_processor_helper = properties && properties.has_key?(:index_processor_helper) ? properties[:index_processor_helper] : nil

      store = properties && properties.has_key?(:store) ? properties[:store] : false
      boost = properties && properties.has_key?(:boost) ? properties[:boost] : 1.0
      type =  properties && properties.has_key?(:type) ? properties[:type] : 'text'

      # Build up our options for the sunspot index call
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

      sunspot_dsl.send(type, tag, opts) do
        if index_processor_helper
          marc.send(index_processor_helper, tag, properties, marc, self)
        else
          marc_index_tag(tag, properties, marc, self)
        end
      end
    end
  end

  def self.marc_index_tag(conf_tag, conf_properties, marc, model)

    # index_helper: fetch a subtag and process the value
    index_helper = conf_properties && conf_properties.has_key?(:index_helper) ? conf_properties[:index_helper] : nil
    # tags can be spefied if the field name it not the tag name
    tag = conf_properties && conf_properties.has_key?(:from_tag) ? conf_properties[:from_tag] : nil
    subtag = conf_properties && conf_properties.has_key?(:from_subtag) ? conf_properties[:from_subtag] : nil

    out = []

    if !tag
      # By convention the first three digits
      tag = conf_tag[0..2]

      # If not a control field
      if conf_tag.length == 4
        subtag = conf_tag[3]
      end

    end

      begin
        marc.each_by_tag(tag) do |marctag|
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

      rescue => e
        puts e.exception
        puts "Marc failed to load for #{model.to_yaml}, check foreign relations, data: #{conf_tag}, #{subtag}"
      end

    return out

  end

end
