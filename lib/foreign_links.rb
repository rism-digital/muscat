module ForeignLinks
  def recreate_links(marc, allowed_relations)
    marc_foreign_objects = Hash.new
    
    # All the allowed relation types *must* be in this array or they will be dropped
    #allowed_relations = ["people", "standard_titles", "standard_terms", "institutions", "catalogues", "liturgical_feasts", "places"]
    
    # Group all the foreign associations by class, get_all_foreign_associations will just return
    # a flat list of objects
    marc.get_all_foreign_associations.each do |object_id, object|
      next if object.is_a? Source
      
      foreign_class = object.class.name.pluralize.underscore
      marc_foreign_objects[foreign_class] = [] if !marc_foreign_objects.include? (foreign_class)
      
      marc_foreign_objects[foreign_class] << object
      
    end
    
    # allowed_relations explicitly needs to contain the classes we will repond to
    # Log if in the Marc there are "unknown" classes, should never happen
    unknown_classes = marc_foreign_objects.keys - allowed_relations
    # If there are unknown classes purge them
    related_classes = marc_foreign_objects.keys - unknown_classes
    
    if !unknown_classes.empty?
      puts "Tried to relate with the following unknown classes: #{unknown_classes.join(',')}"
    end
        
    related_classes.each do |foreign_class|
      relation = self.send(foreign_class)
      
      # The foreign class array holds the correct number of object
      # We want to delete or add only the difference betweend
      # what is in marc and what is in the DB relations
      new_items = marc_foreign_objects[foreign_class] - relation.to_a
      remove_items = relation.to_a - marc_foreign_objects[foreign_class]
      
      # Delete or add to the DB relation
      relation.delete(remove_items)
      begin
        relation << new_items
      rescue => e
        puts
        puts "Foreign Links: Could not add a record in the relationship with #{self.id} (#{self.class})"
        puts "- Added records dump: #{new_items}"
        puts "- Error message follows:"
        puts e.message
      end

      # If this item was manipulated, update also the src count
      # Unless the suppress_update_count is set
      # Since now classes can link between eachother
      # make sure this is updated only when it is a source
      # that triggers the change. In other cases (like people linking to institutions)
      # there is no such count field.
      if self.is_a?(Source)
        if !self.suppress_update_count_trigger && 
          (new_items + remove_items).each do |o|
            o.update_attribute( :src_count, o.sources.count )
          end
        end
      end
      
    end
  end
end
    