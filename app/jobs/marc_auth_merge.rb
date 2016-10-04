require 'progress_bar'

module Util
 class MarcAuthMerge
   
   def initialize(model, dest_auth, src_auth)
     @model = model
     @dest_auth = dest_auth
     @src_auth = src_auth
     @unloadable = {}
     @unsavable = {}
     @progress = false
     
     # Possible links for an auth file
     # For the moment auth files are linked only to sources
     @links_to = ["Source"]
     
   end
   
   def show_progress
     @progress = true
   end
   
   def errors?
     return (@unloadable.count > 0 && @unsavable.count)
   end
   
   def get_unloadable
     @unloadable
   end
   
   def get_unsavable
     @unsavable
   end
   
    def merge_records
      @links_to.each do |link_model|
        update_relations(link_model)
      end

    end

    def update_relations(link_model)
      # 1) Get the remote tags which point to this authority file model
      remote_tags = get_remote_tags_for(link_model)
      
      references =  @src_auth.send(link_model.pluralize.underscore)
  
      if references.count == 0
        puts "#{@model} #{@src_auth.id} has no references to #{link_model}"
        return
      else
        puts "Processing #{references.count} #{link_model}(s) related to #{@model} #{@src_auth.id}"
      end
  
      pb = ProgressBar.new(references.count) if @progress
      references.each do |ref|
    
        pb.increment! if @progress
    
        # load the remote marc
        begin
          marc = ref.marc
          x = marc.to_marc
        rescue => e
          @unloadable[ref.id] = e.exception
          next
        end

        # Now that we have marc let's go through the tags to update
        remote_tags.each do |rtag|
      
          model_marc_conf = MarcConfigCache.get_configuration link_model.downcase
          master = model_marc_conf.get_master(rtag)
      
          marc.each_by_tag(rtag) do |marctag|
            # Get the remote tags
            # is this tag pointing to the id of auth2?
            marc_id = marctag.fetch_first_by_tag(master)
            if !marc_id || !marc_id.content
              puts "#{ref.id} tag #{rtag} does not have subtag #{master}"
              next
            end
        
            # Skip if this link is to another auth file
            next if marc_id.content.to_i != @src_auth.id
        
            # Substitute them
            # Remove all a and d tags
            marctag.each_by_tag("a") {|t| t.destroy_yourself}
            marctag.each_by_tag("d") {|t| t.destroy_yourself}
        
            # Also remove all the old underscores, not used anymore
            marctag.each_by_tag("_") {|t| t.destroy_yourself}
        
            # Sunstitute the id in $0 with the new auth file
            # For some reason just substituting marc_id.content does not work
            # Delete it and make a new tag
            marc_id.destroy_yourself
        
            marctag.add(MarcNode.new(link_model.downcase, master, @dest_auth.id, nil))
            marctag.sort_alphabetically
        
          end
      
        end
    
        # Marc remains cached even after save
        # Create a new marc class and load it
        # with the source from old marc
        # it will resolve externals
        # only then save the source
        classname = "Marc" + link_model
        dyna_marc_class = Kernel.const_get(classname)
  
        new_marc = dyna_marc_class.new(marc.to_marc)
        new_marc.load_source(true)
    
        # set marc and save
        ref.marc = new_marc
        begin
          ref.save
        rescue => e
          @unsavable[ref.id] = e.exception
        end
        
    
      end
    end

    def get_remote_tags_for(link_model)
      remote_tags = []
      model_marc_conf = MarcConfigCache.get_configuration link_model.downcase
  
      model_marc_conf.get_foreign_tag_groups.each do |foreign_tag|
        model_marc_conf.each_subtag(foreign_tag) do |subtag|
          tag_letter = subtag[0]
          if model_marc_conf.is_foreign?(foreign_tag, tag_letter)
            # Note: in the configuration only ID has the Foreign class
            # The others use ^0
            next if model_marc_conf.get_foreign_class(foreign_tag, tag_letter) != @model
            remote_tags << foreign_tag if !remote_tags.include? foreign_tag
          end
        end
      end
      
      remote_tags
    end
    

  end
end
