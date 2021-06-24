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

    modified = false
    w.marc.by_tags("930").each do |t|
        st = t.fetch_first_by_tag("0")
        #puts "Deleting work link"
        t.destroy_yourself
        modified = true
    end
    w.save! if modified
    w = Work.find(id)

    w.referring_works.each do |wr|
        modified = false
        #s.marc.load_source 
        wr.marc.each_by_tag("930") do |t|
            st = t.fetch_first_by_tag("0")
            if st && st.content && st.content == id
                #puts "Deleting work link"
                t.destroy_yourself
                modified = true
            end
        end
        wr.save! if modified
    end

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
    w2 = Work.find(id)
    w2.destroy!
end

def format_opus(opus)
    # remove [] and ?
    opus = opus.gsub(/\[|\]|\?/,"")
    # replace opus
    opus = opus.gsub(/^(opus|Opus|Op.) ?/,'op. ')
    # replace ^No and similar with opus.
    opus = opus.gsub(/^(No|no|Nr|nr)\.? ?/,'op. ') 
    # replace No and similar with /
    opus = opus.gsub(/(,|.)? ?(No|no|Nr|nr)\.? ?/,'/')
    # add space if necessary
    opus = opus.gsub(/^op\.([^\s])/,'op. \1')
    # remove spaces around /
    opus = opus.gsub(/ *\/ */, '/')
    # add spaces with WoO
    opus = opus.gsub(/^WoO([a-zA-Z0-9]*)$/,'WoO \1')
    # add op. for single figures
    opus = opus.gsub(/^([a-zA-Z0-9]*(\/[A-Z0-9]+)?)$/,'op. \1')
    # replace . with /
    opus = opus.gsub(/(^op. [a-zA-Z0-9]*)\.|, ?([0-9A-Z])/,'\1/\2') 
    # remove op. when WoO
    opus = opus.gsub(/(^op. [a-zA-Z0-9]*)(WoO)/,'\2') 
end

def check_opus(opus)
    /^((op. )|(WoO ))[0-9a-zA-Z]*(\/[0-9]+)?$/.match?(opus)
end



