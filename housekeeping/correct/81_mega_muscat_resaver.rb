FILENAME="unloadable.log"
File.write(FILENAME, Time.now.to_s, mode: 'w')

models = [Holding, Institution, Person, Publication, Source, Work, WorkNode]

if !ARGV.empty?
    puts "Resaving only #{ARGV[0]}"
    models = [ARGV[0].constantize]
end

begin_time = Time.now
all_items = 0
all_unsaved = 0

spinner = TTY::Spinner.new("[:spinner] :title", format: :shark)

old_stdout = $stdout
old_stderr = $stderr

models.each do |model|
    begin_model_time = Time.now
    total_items = model.all.count
    saved_items = 0 #With find_in_batches each_with_index does not work!
    unsavable_items = 0
    
    puts "Resaving #{total_items} #{model.to_s.pluralize}"
    spinner.update(title: "Loading #{model.to_s.pluralize}...")
    spinner.auto_spin

    last_batch = 0
    last_time = Time.now
    elapsed = 0

    model.find_in_batches do |batch|
        batch.each do |item|
            if saved_items % 500 == 0

                seconds = Time.now - last_time
                elapsed += seconds
                per_sec = 500 / seconds
                eta = (total_items - saved_items) / per_sec

                spinner.update(title: "#{model.to_s} offset: #{saved_items} appr. #{per_sec.round}/sec (in #{seconds.round}s, tot #{elapsed.round}s ETA #{eta.round}s)") 
                last_time = Time.now
            end
            
            new_stdout = StringIO.new
            $stdout = new_stdout
            $stderr = new_stdout

            begin
                # Do not make a paper trail snapshot
                PaperTrail.request(enabled: false) do
                    item.save
                    saved_items += 1
                end
            rescue
                #puts "Could not save #{model.to_s} #{item.id}"
                File.write(FILENAME, "Could not save #{model.to_s} #{item.id}", mode: 'a+')
                unsavable_items += 1
                all_unsaved += 1
            ensure
                # Set back to original
                $stdout = old_stdout
                $stderr = old_stderr
                new_stdout.rewind
            end

            #$stderr.print "#{model.to_s[0, 3].upcase}#{idx} " if DOTIFY && idx % 1000 == 0

            item = nil
        end
    end

    end_model_time = Time.now
    all_items += total_items - unsavable_items
    puts "Saved #{total_items - unsavable_items} #{model.to_s.pluralize} in #{end_model_time - begin_model_time}"

end

end_time = Time.now
puts "Saved #{all_items} (-#{all_unsaved}) items, started at #{begin_time.to_s} finished at #{end_time.to_s}, (#{end_time - begin_time} seconds run time) "