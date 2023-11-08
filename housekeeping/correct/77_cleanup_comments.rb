deleted = 0
ActiveAdmin::Comment.all.each do |c|

    klass = c.resource_type.constantize
    begin
        resource = klass.find(c.resource_id)
    rescue ActiveRecord::RecordNotFound
        puts "Comment #{c.id} (#{c.resource_type} #{c.resource_id})is stale, deleting, adios!"
        c.destroy
        deleted += 1
    end

end

puts "Deleted #{deleted} orphan comments"