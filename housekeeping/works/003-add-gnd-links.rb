require 'progress_bar'
require './housekeeping/works/functions'

@gnd_works_for_cmp = Hash.new
@gnd_mapping = Hash.new
@mutliple_matches = 0

def get_gnd_works(id, name)
    if (@gnd_works_for_cmp[name]) 
        return @gnd_works_for_cmp[name]
    end
    if id
        gnd_works = @gnd.select{ |w| w["cmp"] and w["cmp"].to_s == id }
        #puts "#{name}\thttp://d-nb.info/gnd/#{id} #{gnd_works.size}"
        if gnd_works.size > 0
            @gnd_works_for_cmp[name] = gnd_works
            return gnd_works
        end
    end
    # try by name
    gnd_works = @gnd.select{ |w| w["cmp-name"] and w["cmp-name"].to_s == name }
    #puts "#{name}\thttp://d-nb.info/gnd/#{id} #{gnd_works.size}"
    @gnd_works_for_cmp[name] = gnd_works
    return gnd_works
end 

def get_opus_alternate(opus)
    alternate = [opus]
    if /\//.match?(opus)
        alternate << opus.gsub(/\//, ", Nr. ")
        alternate << opus.gsub(/\//, ",")
    end
    alternate
end

# example http://d-nb.info/gnd/1165616726 is part of http://d-nb.info/gnd/300110634 (both KV 35)
# we want to map with the top one
def find_top_parent_in_mapping(mapping, force)
    cleaned_up_mapping = mapping.clone
    if force # simply delete all "part-of" if we have only one work which is not
        if cleaned_up_mapping.find{ |w| !w["part-of"] }
            cleaned_up_mapping.delete_if { |w| w["part-of"] }
        end
    else  # delete only "part-of" works that are pointing to one that is also in the list
        mapping.each do |m|
            if m["part-of"] and mapping.find{ |w| w["id"] == m["part-of"] }
                cleaned_up_mapping.delete_if { |w| w["id"] == m["id"] }
            end
        end
    end
    cleaned_up_mapping
end

def find_gnd_works_for_cmp(id, name, opus, cat_a, cat_n)
    gnd_works = get_gnd_works(id, name)
    if (opus)
        # generate alternate forms of the opus for the lookup
        alternates = get_opus_alternate(opus)
        res = gnd_works.select{ |w| w["opus"] and w["opus"].any? { |n| alternates.include?(n) } } 
        # remove part-of matches if possible
        res = find_top_parent_in_mapping(res, false) if res and res.size > 1
        if res and res.size > 0
            #puts "#{name} #{res.size} #{res}"
            @mutliple_matches += 1 if res.size > 1
            return res
        end
    end
    if (cat_a and cat_n)
        cat = "#{cat_a} #{cat_n}"
        res = gnd_works.select{ |w| w["cat"] and w["cat"].include?(cat) } 
        # remove part-of matches if possible
        res = find_top_parent_in_mapping(res, false) if res and res.size > 1
        if res and res.size > 0
            #puts "#{name} #{res.size} #{res}"
            @mutliple_matches += 1 if res.size > 1
            return res
        end
    end
    nil
end

@list = YAML::load(File.read("./002-works.yml"))
@gnd = YAML::load(File.read("./housekeeping/junkyard/works/gnd/gnd.yml"))
@cat_a_mapping = YAML::load(File.read("./housekeeping/works/002-cat-a-mapping.yml"))

pb = ProgressBar.new(@list.size)

@list.each do |item|
    pb.increment!
    cat_a = get_cat_a(item['cmp-id'], @cat_a_mapping, 'gnd', item['cat_a'])
    mapping = find_gnd_works_for_cmp(item['cmp-gnd'], item['cmp-name'], item['opus'], cat_a, item['cat_n'])
    if mapping
        @gnd_mapping[item["w-id"]] = mapping
        item['gnd-mapping'] = mapping.map{ |x| x["id"] }
    end
end

## Saving links
puts "#{@gnd_mapping.size} mapped with #{@mutliple_matches} multiple matches"
pb = ProgressBar.new(@gnd_mapping.size)
@gnd_mapping.each do |key, value|
    pb.increment!
    #puts "#{key} #{value.to_yaml}"
    work = Work.find(key)
    work.marc.load_source false
    delete_links_to(work, "DNB")
    value.each do |gnd_work|
        node = MarcNode.new("work", "024", "", "7#")
        node.add_at(MarcNode.new("work", "a", gnd_work["id"], nil), 0)
        node.add_at(MarcNode.new("work", "2", "DNB", nil), 0)
        node.sort_alphabetically
        work.marc.root.add_at(node, work.marc.get_insert_position("024"))
    end
    #puts work.marc
    work.suppress_reindex
    work.save!
end

File.open( "003-works.yml" , "w") {|f| f.write(@list.to_yaml) }