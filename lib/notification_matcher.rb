class NotificationMatcher

  def initialize(object, user)
    @object = object
    @user = user
  end
  
  def get_matches
    matches = []
    user_notifications = @user.get_notifications
    return false if !user_notifications

    rules = parse_rules(user_notifications)

    rules.each do |model, property_patterns|
      next if @object.class.to_s.downcase != model.downcase

      partial_match = []
      property_patterns.each do |rule|

        if rule[:property] == "lib_siglum" && @object.respond_to?(:siglum_matches?)
          partial_match << "#{rule[:property]} #{rule[:pattern]}" if @object.siglum_matches?(rule[:pattern].gsub("*", ""))
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

    matches
  end
  
  
  private
  
  def wildcard_match(value, pattern)
    escaped = Regexp.escape(pattern).gsub('\*','.*?')
    r = Regexp.new("^#{escaped}$", Regexp::IGNORECASE)
    return value =~ r
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
        parts.each do |part|
          # The first one can be the model 
          if current == 0 && ["source", "work"].include?(part.downcase)
            model = part
          else
            property, pattern = split_line(part)
            next if !property
  
            rules[model] = [] if !rules[model]
            rules[model] << {property: property, pattern: pattern}
  
          end
        end
      else
        property, pattern = split_line(line)
        next if !property
        rules[model] = [] if !rules[model]
        rules[model] << {property: property, pattern: pattern}
      end
    end
    return rules
  end
  
end