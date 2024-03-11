module AuthorityMerge

  def duplicate_to_id(new_id)
    # For debug
    self.wf_audit = :full
        
    new_model = self.class.new
  
    marc_type = self.class.to_s.downcase
    classname = "Marc" + self.class.to_s
    dyna_marc_class = Kernel.const_get(classname)
    new_marc = dyna_marc_class.new(self.marc.to_marc)
    
    new_marc.set_id new_id
  
    new_tag = MarcNode.new(marc_type, "667", "", "##")
    new_tag.add_at(MarcNode.new(marc_type, "a", "Old id: #{self.id.to_s}", nil), 0)

    pi = new_marc.get_insert_position("667")
    new_marc.root.children.insert(pi, new_tag)
  
    # set marc and save
    new_model.marc = new_marc

    # Siglums are unique. Remove it from the old
    # Before saving the new
    if self.is_a? Institution
        self.marc.by_tags("110").each {|t| t.destroy_yourself}
    end
    self.save

    # For debug
    new_model.wf_audit = :minimal
    new_model.save!

    return new_model
  
  end

  def migrate_to_id(new_id)
    
    begin
      new_model = self.class.find(new_id)
    rescue ActiveRecord::RecordNotFound
      puts "Creating new #{new_id}"
      new_model = duplicate_to_id(new_id)
    end
    #include sources and holdings at first
    #TODO probably add more asscociations
    refs = []
    (self.class.reflect_on_all_associations.map{|e| e.name}.select{|e| e.to_s =~ /source|holding/ && !(e.to_s =~ /relations/)}).each do |s|
      refs << self.send(s)
    end

    refs.flatten.uniq.each do |s|
      record_type = s.has_attribute?(:record_type) ? s.record_type : nil
      klass = s.marc.class
      affected_tags = s.marc.change_authority_links(self, new_model)

      new_marc = klass.new(s.marc.to_marc)
      new_marc.load_source(true)
      new_marc.import
      new_marc.deduplicate_tags!(affected_tags)

      # set marc and save
      s.marc = new_marc
      s.record_type = record_type if record_type
      s.paper_trail_event = "#{self.class} change id from #{self.id} to #{new_id}"
      s.save
    end
    
    # EXPERIMENTAL
    # Clear this auth file
    # self.destroy
    
  end

end
