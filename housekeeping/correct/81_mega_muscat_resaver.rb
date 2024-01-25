DOTIFY=true

models = [Holding, Institution, Person, Publication, Source, Work, WorkNode]

begin_time = Time.now
all_items = 0
all_unsaved = 0

models.each do |model|
    begin_model_time = Time.now
    total_items = model.all.count
    unsavable_items = 0
    
    puts "Resaving #{total_items} #{model.to_s.pluralize}"
    
    model.find_in_batches do |batch|
        batch.each_with_index do |item, idx|

            begin
                # Do not make a paper trail snapshot
                PaperTrail.request(enabled: false) do
                    item.save
                end
            rescue
                puts "Could not save #{model.to_s} #{item.id}"
                unsavable_items += 1
                all_unsaved += 1
            end

            $stderr.print "#{model.to_s[0, 3].upcase}#{idx} " if DOTIFY && idx % 1000 == 0

            item = nil
        end
    end

    end_model_time = Time.now
    all_items += total_items - unsavable_items
    puts "Saved #{total_items - unsavable_items} #{model.to_s.pluralize} in #{end_model_time - begin_model_time}"
    
end

end_time = Time.now
puts "Saved #{all_items} (-#{all_unsaved}) items, started at #{begin_time.to_s} finished at #{end_time.tos}, (#{end_time - begin_time} seconds run time) "