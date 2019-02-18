module ForeignLinks
  
  def can_source_to_source?(marc, object_id, object)
    # If one of the two objects is not a source just return true
    # The relation is managed by foreign_links
    return true if !object.is_a?(Source) || !self.is_a?(Source)
    
    # Is this a 773 or 775?
    # 773 is a special case
    # and not managed in foreign_links
    # @note the TAG VALUE 'w' is HARDCODED here
    marc.each_by_tag("773") do |t|
      a = t.fetch_first_by_tag("w")
      if a && a.content
        if a.content.to_i == object_id.to_i
          # This source is referenced by a 773
          # skip it - it is updated in marc.update_77x
          #puts "Skip 773 relation".purple
          return false
        end
      end
    end

    can_manage = false
    marc.each_by_tag("775") do |t|
      a = t.fetch_first_by_tag("w")
      if a && a.content
        if a.content.to_i == object_id.to_i
          #puts "Manage 775 relation".green
          can_manage = true
        end
      end
    end
    
    if !can_manage
      $stderr.puts "Error in source to source relation".red
      $stderr.puts "#{self.id} relation with #{object_id.to_s}".yellow
      $stderr.puts "No 773 or 775 containing that relation is found".red
    end
    
    return can_manage #if it is found we can go on
  end
  
  # recreates the Relations of the current Record to the associated foreign fields
  def recreate_links(marc, allowed_relations)
    marc_foreign_objects = Hash.new
    reindex_items = Array.new
    
    # All the allowed relation types *must* be in this array or they will be dropped
    #allowed_relations = ["people", "standard_titles", "standard_terms", "institutions", "catalogues", "liturgical_feasts", "places"]
    
    # Group all the foreign associations by class, get_all_foreign_associations will just return
    # a flat list of objects
    marc.get_all_foreign_associations.each do |object_id, object|
      # Manage source to source relations
      next if !can_source_to_source?(marc, object_id, object)
      
      foreign_class = object.class.name.pluralize.underscore
      marc_foreign_objects[foreign_class] = [] if !marc_foreign_objects.include? (foreign_class)
      
      marc_foreign_objects[foreign_class] << object
    end
    
    all_foreign_classes = marc.get_all_foreign_classes
    
    # allowed_relations explicitly needs to contain the classes we will repond to
    # Log if in the Marc there are "unknown" classes, should never happen
    unknown_classes = all_foreign_classes - allowed_relations
    # If there are unknown classes purge them
    related_classes = all_foreign_classes - unknown_classes
    if !unknown_classes.empty?
      $stderr.puts "Tried to relate with the following unknown classes: #{unknown_classes.join(',')} [#{self.id}]"
    end
    
    related_classes.each do |foreign_class|
      relation = self.send(foreign_class)
      
      # The foreign class array holds the correct number of object
      # We want to delete or add only the difference betweend
      # what is in marc and what is in the DB relations
      if marc_foreign_objects[foreign_class]
        new_items = marc_foreign_objects[foreign_class] - relation.to_a
        remove_items = relation.to_a - marc_foreign_objects[foreign_class]
      else
        new_items = []
        remove_items = relation.to_a
      end
      
      reindex_items += new_items
      reindex_items += remove_items
      
      # Delete or add to the DB relation
      relation.delete(remove_items)
      new_items.each do |ni|
        begin
          relation << ni
        rescue => e
          $stderr.puts
          $stderr.puts "Foreign Links: Could not add a record (#{ni.id}) in the relationship with #{self.id} (#{self.class})".red
          $stderr.puts "- Added records dump: #{new_items}".magenta
          $stderr.puts e.message.blue
        end
      end
    end
    
    # If this item was manipulated, update also the src count
    # Unless the suppress_update_count is set
    # Since now classes can link between eachother
    # make sure this is updated only when it is a source
    # that triggers the change. In other cases (like people linking to institutions)
    # there is no such count field.
    if self.is_a?(Source) && !self.suppress_update_count_trigger && reindex_items.size > 0
      # just pass the minumum necessary information
      ids_hash = reindex_items.map {|i| {class: i.class, id: i.id}}
      job = Delayed::Job.enqueue(ReindexForeignRelationsJob.new(self.id, ids_hash))
    end
  end
end
    
