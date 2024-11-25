Source.find_in_batches do |batch|

    batch.each do |s|
          
        s.marc.load_source true
        save = false

        s.marc.each_by_tag("001") do |t|
            if t.content.start_with? "0"
                t.content = t.content.to_i.to_s
                save = true
            end
        end

        puts s.marc.get_id

        PaperTrail.request(enabled: false) do
            s.suppress_reindex
            s.suppress_recreate
            s.suppress_update_count
            s.suppress_update_77x

            s.save if save
        end
    end


end