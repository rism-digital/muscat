User.all.each do |u|

    name = u.name.strip.gsub(" ", "_").gsub("-", "_").gsub(".", "").gsub(",", "").gsub("'", "").downcase
    #puts("#{u.name} -> #{name}")
    u.username = name
    begin
        u.save!
    rescue ActiveRecord::RecordNotUnique
        u.username = name + "2"
        u.save
    rescue ActiveRecord::RecordInvalid => ex
        if ex.message.include? "Validation failed: Username has already been taken"
            u.username = name + "2"
            u.save!
        end
        ap name
    end
    #ap mame if ! u.username
    #ap u.username
end