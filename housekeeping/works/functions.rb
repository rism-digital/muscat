require 'solr_search'

def find_work(composer_id, opus, cat_a, cat_n)
    query = Work.solr_search do 
        with("383b", opus) if opus
        with("690a", cat_a) if cat_a and cat_n
        with("690n", cat_n) if cat_a and cat_n
        paginate :page => 1, :per_page => Work.all.count
    end
    query.results.each do |w|
        w.marc.load_source false
        w.marc.each_by_tag("100") do |t|
            t0 = t.fetch_first_by_tag("0")
            return w if t0 and t0.content and t0.content == composer_id
        end
    end
    return nil
end

def delete_work(id)
    w = Work.find(id)
    w.referring_sources.each do |s|
        modified = false
        #s.marc.load_source 
        s.marc.each_by_tag("930") do |t|
            st = t.fetch_first_by_tag("0")
            if st && st.content && st.content == id
                #puts "Deleting work link"
                t.destroy_yourself
                modified = true
            end
        end
        s.save! if modified
    end
    w.destroy
end

