class NotificationMatcher

  ALLOWED_PROPERTIES = {
    source: [:record_type, :std_title, :composer, :title, :shelf_mark, :lib_siglum],
    work: [:title, :form, :notes, :composer]
  }

  SPECIAL_RULES = {
    source: [:lib_siglum, :record_type, :shelf_mark],
    work: [:composer]
  }

  def initialize(object, user)
    if !object.is_a?(Source) && !object.is_a?(Work)
      raise(ArgumentError, "NotificationMatcher can be applied only for Works and Sources" )
    end

    @object = object
    @user = user
  end
  
  def get_matches
    matches = []
    user_notifications = @user.get_notifications
    return false if !user_notifications
    return false if !@object.is_a?(Source) && !@object.is_a?(Work) # This should not happen! 

    rules = parse_rules(user_notifications)

    rules.each do |model, rule_groups|
      next if @object.class.to_s.downcase != model.downcase

      rule_groups.each do |property_patterns|
        partial_match = []
        property_patterns.each do |rule|
          
          next if !allowed?(rule[:property])
          
          if special_case?(rule[:property])
            partial_match << "#{rule[:property]} #{rule[:pattern]}" if special_match(rule[:property], rule[:pattern])
          else
            if @object.respond_to?(rule[:property])
              object_value = @object.send(rule[:property])
              if object_value
                partial_match << "#{rule[:property]} #{rule[:pattern]}" if wildcard_match(object_value, rule[:pattern])
              end
            end
          end

          if partial_match.count == property_patterns.count
            matches << partial_match.join(" AND ")
          end

        end
      end
    end

    matches
  end
  
  
  private
  
  def wildcard_match(value, pattern)
    escaped = Regexp.escape(pattern).gsub('\*','.*?')
    r = Regexp.new("^#{escaped}$", Regexp::IGNORECASE)
    return value =~ r
  end

  def special_match(property, pattern)
    if property == "lib_siglum"
      return @object.siglum_matches?(pattern.gsub("*", ""))
    elsif property == "record_type"
      if MarcSource::RECORD_TYPES.include?(pattern.downcase.to_sym)
        return @object.record_type == MarcSource::RECORD_TYPES[pattern.downcase.to_sym]
      end
    elsif property == "shelf_mark"
      if @object.record_type == MarcSource::RECORD_TYPES[:collection] || 
         @object.record_type == MarcSource::RECORD_TYPES[:source] ||
         @object.record_type == MarcSource::RECORD_TYPES[:libretto_source] ||
         @object.record_type == MarcSource::RECORD_TYPES[:theoretica_source] ||
         @object.record_type == MarcSource::RECORD_TYPES[:composite_volume]
        return wildcard_match(@object.shelf_mark, pattern)
      else
        if @object.record_type == MarcSource::RECORD_TYPES[:edition] ||
          @object.record_type == MarcSource::RECORD_TYPES[:libretto_edition] ||
          @object.record_type == MarcSource::RECORD_TYPES[:theoretica_edition]
          holdings = @object.holdings
        else
          holdings = @object.parent_source.holdings
        end
        holdings.each do |holding|
          return true if wildcard_match(holding.marc.get_shelf_mark, pattern)
        end
      end 
    elsif @object.is_a?(Work) && property == "composer"
      return false if !@object.person
      composer = @object.person.name
      return wildcard_match(composer, pattern)
    end

    false
  end


  def split_line(line)
    parts = line.strip.split(":")
    return false if parts.count != 2
    return false if parts[0].empty? # :xxx case
  
    property = parts[0]
    pattern = parts[1]
    return property, pattern
  end
  
  def parse_rules(rule_queries)
    rules = {}
    rule_queries.each do |l|
      line = l.strip
 
      model = "source"
      property = ""
      pattern = ""
  
      if line.include?(" ")
        parts = line.split(" ")
  
        current = 0
        rule_group = []
        parts.each do |part|
          # The first one can be the model 
          if current == 0 && ["source", "work"].include?(part.downcase)
            model = part
          else
            property, pattern = split_line(part)
            next if !property
  
            rule_group << {property: property, pattern: pattern}
          end
        end

        rules[model] = [] if !rules[model]
        rules[model] << rule_group

      else
        property, pattern = split_line(line)
        next if !property
        rules[model] = [] if !rules[model]
        ## Here we have only one rule in the group
        rules[model] << [{property: property, pattern: pattern}]
      end
    end
    return rules
  end
  
  def allowed?(field)
    return ALLOWED_PROPERTIES[@object.class.to_s.downcase.to_sym].include? field.downcase.to_sym
  end

  def special_case?(field)
    return SPECIAL_RULES[@object.class.to_s.downcase.to_sym].include? field.downcase.to_sym

  end

end