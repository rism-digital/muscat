require 'progress_bar'
require './housekeeping/works/functions'

@bnf = Hash.new
@works_by_cmp = Hash.new
@cmp_name_mapping = Hash.new
@mutliple_matches = 0

@bnf_works_for_cmpmapping = Hash.new

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

def find_bnf_works_for_cmp(id, name, opus, cat_a, cat_n)
    bnf_works_for_cmpworks = get_works_for_cmp(id, name, @bnf, @works_by_cmp, @cmp_name_mapping)
    if (opus)
        # generate alternate forms of the opus for the lookup
        alternates = get_opus_alternate(opus)
        res = bnf_works_for_cmpworks.select{ |w| w["opus"] and w["opus"].any? { |n| alternates.include?(n) } } 
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
        res = bnf_works_for_cmpworks.select{ |w| w["cat"] and w["cat"].include?(cat) } 
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

@list = YAML::load(File.read("./003-works.yml"))
@bnf = YAML::load(File.read("./housekeeping/junkyard/works/bnf/bnf.yml"))
@cat_a_mapping = YAML::load(File.read("./housekeeping/works/002-cat-a-mapping.yml"))

# First make a lookup of names and look in alternate names for the ones missing
cmp_name_mapping_file = "./004-cmp-names.yml"
if File.file?(cmp_name_mapping_file)
    @cmp_name_mapping = YAML::load(File.read(cmp_name_mapping_file))
else
    puts "Mapping names...."
    names = @bnf.map{|w| w['cmp-name']}.uniq

    # names to remove
    names.delete("Bach, Johann Sebastian")
    names.delete("Call, Leonhard von")

    get_name_mapping(names, @cmp_name_mapping)
    File.open(cmp_name_mapping_file, "w") {|f| f.write(@cmp_name_mapping.to_yaml) }
    puts "#{@cmp_name_mapping.size} names mapped"
end

pb = ProgressBar.new(@list.size)

@list.each do |item|
    pb.increment!
    cat_a = get_cat_a(item['cmp-id'], @cat_a_mapping, 'bnf', item['cat_a'])
    mapping = find_bnf_works_for_cmp(item['cmp-gnd'], item['cmp-name'], item['opus'], cat_a, item['cat_n'])
    if mapping
        @bnf_works_for_cmpmapping[item["w-id"]] = mapping
        item['bnf-mapping'] = mapping.map{ |x| x["id"] }
    end
end

## Saving links
puts "#{@bnf_works_for_cmpmapping.size} mapped with #{@mutliple_matches} multiple matches"

pb = ProgressBar.new(@bnf_works_for_cmpmapping.size)
@bnf_works_for_cmpmapping.each do |key, value|
    pb.increment!
    work = Work.find(key)
    work.marc.load_source false
    delete_links_to(work, "BNF")
    value.each do |bnf_works_for_cmpwork|
        node = MarcNode.new("work", "024", "", "7#")
        node.add_at(MarcNode.new("work", "a", bnf_works_for_cmpwork["id"], nil), 0)
        node.add_at(MarcNode.new("work", "2", "BNF", nil), 0)
        node.sort_alphabetically
        work.marc.root.add_at(node, work.marc.get_insert_position("024"))
    end
    #puts work.marc
    work.suppress_reindex
    work.save!
end

File.open( "004-works.yml" , "w") {|f| f.write(@list.to_yaml) }