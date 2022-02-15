#require 'solr_search'

def self.cat_extract(value)
    value.gsub(/\/.*/,"")
end

# Graupner
# id 83288
# gnd 118718517
def self.cat_extract_83288(value)
    if /1[1|2|3]\d\d\//.match?(value)
        value.gsub(/(....\/[^ |\/]*).*/,'\1')
    else 
        cat_extract(value)
    end
end

def self.cat_extract_gnd_118718517(value)
    if /1[1|2|3]\d\d[ |,]/.match?(value)
        value.gsub(/(\d...).(.*)/,'\1/\2')
    else 
        value.gsub(/,.*/,"")
    end
end


def get_cat_a(cmp_id, cat_a_mapping, set, cat_a)
    return nil if cat_a == nil
    return cat_a if (!cat_a_mapping[cmp_id])
    #puts cat_a_mapping[cmp_id][set][1]
    return cat_a_mapping[cmp_id][set][1]
end 

def get_works_for_cmp(id, name, works, works_by_cmp, cmp_name_mapping)
    if (cmp_name_mapping[name])
        name = cmp_name_mapping[name]
    end
    if (works_by_cmp[name]) 
        return works_by_cmp[name]
    end
    if id
        works_for_cmp = works.select{ |w| w["cmp"] and w["cmp"].to_s == id }
        if works_for_cmp.size > 0
            works_by_cmp[name] = works_for_cmp
            #puts "GND!"
            return works_for_cmp
        end
    end
    # try by name
    works_for_cmp = works.select{ |w| w["cmp-name"] and w["cmp-name"].to_s == name }
    #puts "#{name}\thttp://d-nb.info/mb/#{id} #{mb_works_for_cmpworks.size}"
    works_by_cmp[name] = works_for_cmp
    return works_for_cmp
end 

def get_name_mapping(names, cmp_name_mapping)
    names.delete(nil)
    pb = ProgressBar.new(names.size)
    names.each do |c|
        pb.increment!
        next if /"/.match?(c)
        p = Person.where(full_name: "#{c}")
        if p.size == 0
            # for some reason (encoding?) we also need to substitue - with %
            p = Person.where("alternate_names LIKE \"%#{c.gsub(/‐/,'%')}%\"")
            if p.size > 0
                cmp_name_mapping[p[0].full_name] = c
            end
        end
    end
end

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

def delete_links_to(w, code)
    w.marc.by_tags("024").each do |t|
        t2 = t.fetch_first_by_tag("2")
        t.destroy_yourself if t2 and t2.content and t2.content == code
    end
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



