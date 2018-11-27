class NotificationMatcher

  def initialize(object, user)
    @object = object
    @user = user
    @matches = []
  end
  
  def matches?
    user_notifications = @user.get_notifications
    return false if !user_notifications

    user_notifications.each do |field_name, patterns|

      patterns.each do |pattern|

        if @object.respond_to?(field_name)
          object_value = @object.send(field_name)
          if object_value
            @matches << "#{field_name} #{pattern}" if wildcard_match(object_value, pattern)
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