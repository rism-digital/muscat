#StandardTitle.all.each {|st| st.title_sanit = st.title.strip; st.save; st.suppress_reindex; puts st.id}

#ALTER TABLE standard_titles ADD COLUMN title_sanit VARCHAR(255);
#UPDATE standard_titles SET title_sanit = TRIM(title);
#UPDATE standard_titles SET title_sanit = TRIM(CHAR(9) from TRIM(title));
#ALTER TABLE standard_titles ADD INDEX (title_sanit);

def get_foreign_tags_for(model, foreign_model_name)
    foreign_fields = []
    mc = MarcConfigCache.get_configuration(model)

    mc.get_foreign_tag_groups.each do |tag|

        master = mc.get_master(tag)
        foreign_model = mc.get_foreign_class(tag, master)

        next if foreign_model != foreign_model_name

        foreign_fields << {tag: tag, master: master}
    end
    return foreign_fields
end

def fix_marc_record(model, model_id, foreign_class, old_foreign, new_foreign)

    marc_fields = get_foreign_tags_for(model, foreign_class.to_s)

    model_sym = model.camelize.constantize

    record = model_sym.find(model_id)
    save = false

    marc_fields.each do |mf|
        record.marc.each_by_tag(mf[:tag]) do |t|
            tgs = t.fetch_all_by_tag(mf[:master])

            puts "multiple master!" if tgs.count > 1

            tgs.each do |tt|
                # Since we are manipulating the master, we need to do it this way
                # masters are integers
                if tt.content == old_foreign.to_i
                    t.add_at(MarcNode.new("source", "0", new_foreign.to_i, nil), 0 ) 
                    tt.destroy_yourself
                    t.sort_alphabetically
                    save = true
                end
            end
        end
    end

    #ap record.marc
    record.paper_trail_event = "#{foreign_class} #{old_foreign} -> #{new_foreign}"
    record.save if save
    puts "Saved #{record.id}" if save
end

def nuke_ids(old_id, new_id)

    tables = ["sources_to_standard_titles", "work_nodes_to_standard_titles", "works_to_standard_titles"]
    models = ["sources", "work_nodes", "works"]

    # Get all the record with our old id
    st = StandardTitle.find(old_id)

    models.each do |m|
        referring_items = st.send("referring_" + m)
        puts "Fix #{referring_items.count} #{m}"
        referring_items.each do |ri|
            fix_marc_record(m.singularize, ri.id, "StandardTitle", old_id, new_id)
        end
    end

    tables.each do |t|
        StandardTitle.find_by_sql("UPDATE #{t} set standard_title_id = #{new_id} where standard_title_id = #{old_id}")
    end

    StandardTitle.find_by_sql("DELETE FROM standard_titles where id = #{old_id}")
end

used_ids = []
count = 0

StandardTitle.all.each do |st|

    dups = StandardTitle.where(title_sanit: st.title.strip)

    if dups.count > 1

        next if used_ids.include? st.id

        ids = dups.collect {|d| d.id} - [st.id]
        used_ids += ids

        puts "#{st.id}: #{dups.count} #{st.title} #{ids}"
        count += 1

        # Adios amigos
        ids.each {|id| nuke_ids(id, st.id)}
    end

end

puts used_ids.sort.uniq.count
puts count