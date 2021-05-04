class NotificationMatcher

  def initialize(object, user)
    @object = object
    @user = user
    @matches = []
  end
  
  def matches?
    user_notifications = @user.get_notifications
    return false if !user_notifications

    user_notifications.each do |composite_field_name, patterns|

      # If the field name includes a -, threat it as
      # model-field, such as source-lib_siglum or
      # work-title
      fields = composite_field_name.split("-")
      if fields.count == 2
        model = fields[0]
        field_name = fields[1]

        next if @object.class.to_s.downcase != model.downcase
      else
        field_name = composite_field_name
      end

      patterns.each do |pattern|

        if field_name == "lib_siglum" && @object.respond_to?(:siglum_matches?)
          @matches << "#{field_name} #{pattern}" if @object.siglum_matches?(pattern.gsub("*", ""))
        else
          if @object.respond_to?(field_name)
            object_value = @object.send(field_name)
            if object_value
              @matches << "#{field_name} #{pattern}" if wildcard_match(object_value, pattern)
            end
          end
        end

      end
      
    end

    return @matches.count > 0
  end
  
  def get_matches
    @matches
  end
  
  private
  
  def wildcard_match(value, pattern)
    escaped = Regexp.escape(pattern).gsub('\*','.*?')
    r = Regexp.new("^#{escaped}$", Regexp::IGNORECASE)
    return value =~ r
  end
  
end