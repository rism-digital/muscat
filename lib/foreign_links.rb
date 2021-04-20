module ForeignLinks

  def recreate_links(marc, allowed_relations)
    marc_foreign_objects = Hash.new
    reindex_items = Array.new
    
    # All the allowed relation types *must* be in this array or they will be dropped
    #allowed_relations = ["people", "standard_titles", "standard_terms", "institutions", "publications", "liturgical_feasts", "places"]
    
    # Group all the foreign associations by class, get_all_foreign_associations will just return
    # a flat list of objects
    # foreign_links_only: true checks the Marc configuration, some tags (i.e. 773) are managed separately 
    marc.each_foreign_association(foreign_links_only: true) do |object, tag, relator_code|
    
      foreign_class = object.class.name.pluralize.underscore
      marc_foreign_objects[foreign_class] = [] if !marc_foreign_objects.include? (foreign_class)
      

      if through_relation?(foreign_class)
        marc_foreign_objects[foreign_class] << {object: object, tag: tag, relator_code: relator_code}
      else
        marc_foreign_objects[foreign_class] << object
      end

    end
    
    all_foreign_classes = marc.get_all_foreign_classes
    
    # allowed_relations explicitly needs to contain the classes we will repond to
    # Log if in the Marc there are "unknown" classes, should never happen
    unknown_classes = all_foreign_classes - allowed_relations
    # If there are unknown classes purge them
    related_classes = all_foreign_classes - unknown_classes
    if !unknown_classes.empty?
      $stderr.puts "Tried to relate with the following unknown classes: #{unknown_classes.join(',')} [#{self.id}, #{self.class}]"
    end

    related_classes.each do |foreign_class|
      if marc_foreign_objects[foreign_class]
        if through_relation?(foreign_class)
          reindex_items += update_has_many_through(marc_foreign_objects[foreign_class], foreign_class)
        else
          reindex_items += update_has_many_belong_to_many_links(marc_foreign_objects[foreign_class], foreign_class)
        end
      else
        # If we have an empty relation set, make sure no relations of this type are still on the DB
        purge_foreign_items(foreign_class)
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

  def referring_dependencies
    res = {}
    # all other classes with relation to this class from the MarcConfig
    linked_classes = MarcConfigCache.get_referring_associations_for self.class
    #print linked_classes

    self.class.reflect_on_all_associations.each do |assoc|
      # do not check versions or workgroups
      next if assoc.name == :versions || assoc.name == :workgroups
      check = false
      check = true if assoc.plural_name == "digital_objects"
      linked_classes.each do |e|
        # set the check flag if the assiociation matches the marc relation class
        if assoc.plural_name =~ Regexp.new(e)
          check = true
          break
        end
      end
      if check
        puts assoc.plural_name
        dependency_size = self.send(assoc.plural_name).size rescue next
        res[assoc.plural_name] = dependency_size
      end
    end
    return res
  end

  def check_dependencies
    msg = self.referring_dependencies.select { |key, value| value > 0  }
    unless msg.empty?
      linked_objects = "#{msg.map{|k,v| "#{v} #{k.to_s.sub("_", " ")}"}.to_sentence}"
      errors.add :base, %{The #{self.class} could not be deleted because it is used by 
      #{linked_objects}  }
      raise ActiveRecord::RecordNotDestroyed, "Record #{self.class} #{self.id} has active dependencies [#{msg.keys.join}]"
    end
  end

  def through_relation?(foreign_class)
    # Skip "belong to" relations
    return false if !self.class.reflect_on_association(foreign_class)
    self.class.reflect_on_association(foreign_class).through_reflection?
  end

  def get_through_table_name(foreign_class)
    self.class.reflect_on_association(foreign_class).through_reflection.klass
  end

  def update_has_many_belong_to_many_links(foreign_objects, foreign_class)
    reindex_items = []
    relation = self.send(foreign_class)
    # The foreign class array holds the correct number of object
    # We want to delete or add only the difference betweend
    # what is in marc and what is in the DB relations
    new_items = foreign_objects - relation.to_a
    remove_items = relation.to_a - foreign_objects

    reindex_items += new_items
    reindex_items += remove_items
    
    # Delete or add to the DB relation
    relation.delete(remove_items)
    new_items.each do |ni|
        relation << ni
    end

    return reindex_items
  end

  # This function is able to infer the :through table name in a relation
  # declared like this:
  # has_many :source_relations, foreign_key: "source_a_id"
  # has_many :sources, through: :source_relations, source: :source_b
  # (which in this case is SourceRelation). As a convention, the link table
  # MUST have tree additional columns: id, marc_tag, relator_code. All the
  # relations managed by this class must have them. For the actual foreign keys
  # there are two ways it is done. If the relation is to the same class
  # i.e. Source to Source, the columns bust be source_a_id and source_b_id. For
  # example if this is a Person to Person, it must be person_a_id and person_b_id.
  # If the relation is between two different models, the RAILS naming style is used.
  # So for example Source to Person uses source_id and person_id (singular form).
  def update_has_many_through(foreign_objects, foreign_class)
    reindex_items = []

    # Get the through_table
    through_table = get_through_table_name(foreign_class)

    # We need to manipulate directly the items in the Link table
    through_relation_items = self.send(through_table.name.pluralize.underscore)

    # Get the relations names
    # First case: same model, hardcode _a and _b
    if self.class.name.pluralize.underscore == foreign_class
      link_name_from = foreign_class.singularize + "_a"
      link_name_to = foreign_class.singularize + "_b"
    else
      # Second case, different model, rails-style singular form
      link_name_from = self.class.name.underscore
      link_name_to = foreign_class.singularize
    end

    # Go through all the relation items and delete the ones
    # that have no correspondence to the ones in the MARC data
    through_relation_items.each do |r|
      found = false
      foreign_objects.each do |obj|
        found = true if obj[:object].id == r[link_name_to + "_id"] && obj[:tag] == r.marc_tag && obj[:relator_code] == r.relator_code
      end

      if !found
        reindex_items << r
        through_table.destroy(r.id) 
      end
    end
  
    # Now traverse the links in MARC and create just the missing ones
    foreign_objects.each do |obj_and_metadata|
      # We use fin_or_create_by with a block so the item is automatically cread
      # The options are as hash so we can pass the calculated foreign keys
      options = {}
      options[link_name_from] = self
      options[link_name_to] = obj_and_metadata[:object]
      options[:marc_tag] = obj_and_metadata[:tag]
      options[:relator_code] = obj_and_metadata[:relator_code]
      # This is eqivalent to this call:
      #link_element = through_table.find_or_create_by(source_a: self, source_b: obj_and_metadata[:object], marc_tag: obj_and_metadata[:tag], relator_code: obj_and_metadata[:relator_code])


      # The block is passed only to .create, so the code is executed only
      # When the link is created. We do not want to rendex stuff if not necessary
      link_element = through_table.find_or_create_by(options) do |new_object|
        reindex_items << obj_and_metadata[:object]
      end
    end

    return reindex_items
  end

  def purge_foreign_items(foreign_class)
    relation = self.send(foreign_class)
    reindex_items = relation.to_a
    relation.delete(relation.to_a)
    return reindex_items
  end

end
    
