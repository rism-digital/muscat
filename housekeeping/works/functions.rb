#require 'solr_search'

def self.cat_extract(value)
    value.gsub(/\/.*/,"")
end

# Graupner
# Number can be GWV x or GWV x/x
def self.cat_extract_graupner_83288(value)
    if /1[1|2|3]\d\d\//.match?(value)
        value.gsub(/(....\/[^ |\/]*).*/,'\1')
    else 
        cat_extract(value)
    end
end

# Graupner
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

#################################################################################
# function that extract the work for a item with
# - composer_id
# - composer_name
# - catalogue_id
# - catalogue_short_name
# - catalogue_extraction (optional)

def process_works_for(item, function)
    puts "Extract works for: #{item[:composer_name]} (#{item[:composer_id]})"
    pb = ProgressBar.new(SourcePersonRelation.where(person_id: item[:composer_id], marc_tag: "100").count)

    SourcePersonRelation.where(person_id: item[:composer_id], marc_tag: "100").find_in_batches do |batch|
        batch.each do |spr|
            pb.increment!
            send(function, item, spr.source)
        end
    end
end

#################################################################################
# check if work is already in the db

def find_work_list_db(composer_id, opus, cat_a, cat_n)
    w_opus = nil
    w_cat = nil
    w_both = nil
    # we have both an opus and a catalogue number
    if opus and cat_a and cat_n
        w_both = Work.find_by(person_id: composer_id, opus: "op. #{opus}", catalogue: "#{cat_a} #{cat_n}")
        #@list.find{|w| w["opus"] == opus and w["cat_a"] == cat_a and w["cat_n"] == cat_n and w["cmp-id"] == composer_id}
    end
    # return the one matching both if any
    return w_both if w_both

    if opus
        w_opus = Work.find_by(person_id: composer_id, opus: "op. #{opus}")
        #w_opus = @list.find{|w| w["opus"] == opus and w["cmp-id"] == composer_id}
    end
    if cat_a and cat_n
        w_cat = Work.find_by(person_id: composer_id, catalogue: "#{cat_a} #{cat_n}")
        #w_cat = @list.find{|w| w["cat_a"] == cat_a and w["cat_n"] == cat_n and w["cmp-id"] == composer_id}
    end
    # maybe we need to log cases where opus and catalogue mis-match
    #if w_opus and w_cat and w_opus['w-id'] != w_cat['w-id']
    #    #puts "Discrepancy #{w_opus['cmp']}: #{w_opus['title']} #{w_opus['opus']} #{w_opus['cat_n']} | #{w_cat['opus']} | #{w_cat['cat_n']}"
    #end
    # give prececence to catalogue number
    return w_cat ? w_cat : w_opus
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

def check_arr(arrangement)
    return (arrangement == "Arr") ? true : false
end

def check_subheading(subheading)
    return true if subheading == "Excerpts"
    return true if subheading == "Fragments"
    return true if subheading == "Sketches"
    return false
end

def check_opus(opus)
    /^((op. )|(WoO ))[0-9a-zA-Z]*(\/[0-9]+)?$/.match?(opus)
end



