User.all.each do |u|

    name = u.name.strip.gsub(" ", "_").gsub("-", "_").gsub(".", "").gsub(",", "").gsub("'", "").downcase
    puts("#{u.name} -> #{name}")
    u.username = name
    begin
        u.save
    rescue ActiveRecord::RecordNotUnique
        u.username = name + "2"
        u.save
    end
end