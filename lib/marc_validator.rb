class MarcValidator
  
  def initialize(source)
    @rules = EditorValidation.get_default_validation(source).rules
    #ap @rules
    @errors = {}
    @source = source
  end
  
  def validate
    
    @rules.each do |tag, tag_rules|
      
      mandatory =  tag_rules["tags"].has_value? "mandatory"
      #ap rules["tags"]
      
      marc_tags = @source.marc.by_tags(tag)
      
      if marc_tags.count == 0
        # This tag has to be there if "mandatory"
        if mandatory
          @errors[tag] = "mandatory"
          puts "Missing #{tag}, mandatory"
        end
        next
      end
      
      tag_rules["tags"].each do |subtag, rule|
        
        # The validation is per subtag basis
        # THis means that a whole tag, i.e. 856
        # can be missing and validation will pass
        # For a whole tag to be there - no matter the contents
        # the "mandatory" rule above is used
        # Here we validate the contents of the tag, i.e. $a, $b etc
        # The subtags will trigger validation error if missing
        # when required
        
        if is_subtag_excluded(tag, subtag)
          puts "Skip #{tag} #{subtag} because of tag_overrides"
          next
        end
        
        marc_tags.each do |marc_tag|
          
          marc_subtag = marc_tag.fetch_first_by_tag(subtag)
          #ap marc_subtag
          
          if rule.is_a? String
            
            if rule == "required" || rule == "required, warning"
              if !marc_subtag || !marc_subtag.content
                @errors["#{tag}#{subtag}"] = rule
                puts "Missing #{tag} #{subtag}, #{rule}"
              end
            else
              puts "Unknown rule #{rule}" if rule != "mandatory"
            end
            
          elsif rule.is_a? Hash
            if rule.has_key?("required_if")
              # This is another hash! gotta love json
              rule["required_if"].each do |other_tag, other_subtag|
                # Try to get this other tag first
                # the validation passes if it is not there
                other_marc_tag = @source.marc.first_occurance(other_tag)
                if other_marc_tag
                  other_marc_subtag = other_marc_tag.fetch_first_by_tag(other_subtag)
                  # The other subtag is there. see if we have the subtag 
                  # that is required bu the "other" one
                  if other_marc_subtag && other_marc_subtag.content
                    # if it is not here raise an error
                    if !marc_subtag || !marc_subtag.content
                      @errors["#{tag}#{subtag}"] = "required_if-#{other_tag}#{other_subtag}"
                      puts "Missing #{tag} #{subtag}, required_if-#{other_tag}#{other_subtag}"
                    end
                  end
                end
              end
            end
          end
        
        end
      
      end
    
    end
  
  end
  
  def to_s
    @errors.each do |tag, message|
        puts "#{@source.id}\t#{tag}\t#{message}"
    end
  end
  
  private
  
  def is_subtag_excluded(tag, subtag)
        
    # Skip tags based on configuration
    # i.e. collections have different tags
    tag_overrides = @rules[tag]["tag_overrides"]
    if tag_overrides && tag_overrides["exclude"][subtag]
      if tag_overrides["exclude"][subtag].include?(@source.get_record_type.to_s)
        return true
      end
    end
    return false
  end
  
end