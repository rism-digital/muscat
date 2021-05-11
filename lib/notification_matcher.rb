class NotificationMatcher

  ALLOWED_MODELS = ["source", "work", "institution"]

  ALLOWED_PROPERTIES = {
    source: [:record_type, :std_title, :composer, :title, :shelf_mark, :lib_siglum],
    work: [:title, :form, :notes, :composer],
    institution: [:siglum, :name, :address, :place, :comments, :alternates, :notes]
  }

  SPECIAL_RULES = {
    source: [:lib_siglum, :record_type, :shelf_mark],
    work: [:composer]
  }

  def initialize(object, user)
    if !object.is_a?(Source) && !object.is_a?(Work) && !object.is_a?(Institution) 
      raise(ArgumentError, "NotificationMatcher can be applied only for Works and Sources" )
    end

    @object = object
    @user = user
  end
  
  def get_matches
    matches = []
    user_notifications = @user.get_notifications
    return false if !user_notifications
##    return false if !@object.is_a?(Source) && !@object.is_a?(Work) # This should not happen! 

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
    pattern = parts[1].gsub('"', '')
    return property, pattern
  end
  
  def parse_unquoted(line)
    rule_group = []
    ungrouped = []

    # multipart string, such as
    # model property:pattern property2:pattern2
    # we split it in the spaces, and the by :
    # words that are not grouped by : (like the initial
    # model specifier), end ungrouped, and if not a valid
    # model name then discarted. Everyting else is discarded.
    if line.include?(" ")
      parts = line.split(" ")

      parts.each do |part|
        if part.include?(":")
          property, pattern = split_line(part)
          next if !property
          rule_group << {property: property, pattern: pattern}
        else
          ungrouped << part
        end
      end
      
    else
      # There is just one rule in the line
      # is this a valid rule? form xxx:yyy
      if line.include?(":")
        property, pattern = split_line(line)
        # If we cannot parse it, return
        return false if !property
        rule_group << {property: property, pattern: pattern}
      else
        # if we only have one word, return it as ungrouped
        # as it may be in the beginning of the line
        # model property:"pattern" is this case
        ungrouped << line
      end
    end

    # rule_group can be empty if there is only one word
    # in the line
    return rule_group, ungrouped
  end

  def parse_line(rule_query)
    rules = []
    single_tokens = []

    # If we have quoted strings, it means there can be spaces
    # inside. So the string is matched with a regex that
    # extracts the whole property:"pattern" as one token
    # Non-matched parts are still included in the array and
    # are parsed separately
    if rule_query.include?('"')
      parts = rule_query.split(/([^:\s]+:"[^:]+)"/)
      parts.reject! { |c| c.blank? }
    else
      # No quotes - consider the query just one-part
      parts = [rule_query]
    end

    parts.each do |part|
      # property:"pattern" - each element will contain only
      # one of these, so we can safely split it
      if part.include?('"')
        property, pattern = split_line(part)
        next if !property
        rules << {property: property, pattern: pattern}
      else
        # In this case we can have a mixture of model specifiers
        # and rules, such as model property:patter or just model
        # or just property:patter. We parse each one of these
        # (or a whole line if there are no quoted rules)
        # to get a list of property:patter and "ungrouped" words
        # By default, the first of these "ungrouped" or single token
        # words is the model. The others are ignored.
        rule_group, ungrouped = parse_unquoted(part)
        next if !rule_group

        rules += rule_group if !rule_group.empty?
        single_tokens += ungrouped
      end
    end

    if !single_tokens.empty? && ALLOWED_MODELS.include?(single_tokens[0]) 
      model = single_tokens[0]
    else
      model = "source"
    end
    return model, rules
  end

  def parse_rules(rule_queries)
    rules = {}
    rule_queries.each do |l|

      line = l.strip
      model, rules_line = parse_line(line)

      rules[model] = [] if !rules[model]
      rules[model] << rules_line

    end
    return rules
  end
  
  def allowed?(field)
    return ALLOWED_PROPERTIES[@object.class.to_s.downcase.to_sym].include? field.downcase.to_sym
  end

  def special_case?(field)
    return false if !SPECIAL_RULES.include? @object.class.to_s.downcase.to_sym
    return SPECIAL_RULES[@object.class.to_s.downcase.to_sym].include? field.downcase.to_sym

  end

end