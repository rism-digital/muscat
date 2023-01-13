require 'progress_bar'
require './housekeeping/works/functions'

@mb = Hash.new
@works_by_cmp = Hash.new
@cmp_name_mapping = Hash.new
@mutliple_matches = 0

@mb_works_for_cmpmapping = Hash.new

def find_mb_works_for_cmp(id, name, opus, cat_a, cat_n)
    mb_works_for_cmpworks = get_works_for_cmp(id, name, @mb, @works_by_cmp, @cmp_name_mapping)
    if (opus)
        res = mb_works_for_cmpworks.select{ |w| w["opus"] and w["opus"].include?(opus) } 
        # remove part-of matches if possible
        #res = find_top_parent_in_mapping(res, false) if res and res.size > 1
        if res and res.size > 0
            #puts "#{name} #{res.size} #{res}"
            @mutliple_matches += 1 if res.size > 1
            return res
        end
    end
    if (cat_a and cat_n)
        cat = "#{cat_a} #{cat_n}"
        res = mb_works_for_cmpworks.select{ |w| w["cat"] and w["cat"].include?(cat) } 
        # remove part-of matches if possible
        #res = find_top_parent_in_mapping(res, false) if res and res.size > 1
        if res and res.size > 0
            #puts "#{name} #{res.size} #{res}"
            @mutliple_matches += 1 if res.size > 1
            return res
        end
    end
    nil
end

@list = YAML::load(File.read("./004-works.yml"))
@mb = YAML::load(File.read("./housekeeping/junkyard/works/mb/mb.yml"))
@cat_a_mapping = YAML::load(File.read("./housekeeping/works/002-cat-a-mapping.yml"))

# First make a lookup of names and look in alternate names for the ones missing
cmp_name_mapping_file = "./005-cmp-names.yml"
if File.file?(cmp_name_mapping_file)
    @cmp_name_mapping = YAML::load(File.read(cmp_name_mapping_file))
else
    puts "Mapping names...."
    names = @mb.map{|w| w['cmp-name']}.uniq
    get_name_mapping(names, @cmp_name_mapping)
    File.open(cmp_name_mapping_file, "w") {|f| f.write(@cmp_name_mapping.to_yaml) }
    puts "#{@cmp_name_mapping.size} names mapped"
end

pb = ProgressBar.new(@list.size)

@list.each do |item|
    pb.increment!
    cat_a = get_cat_a(item['cmp-id'], @cat_a_mapping, 'mbz', item['cat_a'])
    mapping = find_mb_works_for_cmp(nil, item['cmp-name'], item['opus'], cat_a, item['cat_n'])
    if mapping
        @mb_works_for_cmpmapping[item["w-id"]] = mapping
        item['mb-mapping'] = mapping.map{ |x| x["uuid"] }
    end
end

## Saving links
puts "#{@mb_works_for_cmpmapping.size} mapped to MB with #{@mutliple_matches} multiple matches"

pb = ProgressBar.new(@mb_works_for_cmpmapping.size)
@mb_works_for_cmpmapping.each do |key, value|
    pb.increment!
    work = Work.find(key)
    work.marc.load_source false
    delete_links_to(work, "MBZ")
    value.each do |mb_works_for_cmpwork|
        node = MarcNode.new("work", "024", "", "7#")
        node.add_at(MarcNode.new("work", "a", mb_works_for_cmpwork["uuid"], nil), 0)
        node.add_at(MarcNode.new("work", "2", "MBZ", nil), 0)
        node.sort_alphabetically
        work.marc.root.add_at(node, work.marc.get_insert_position("024"))
    end
    #puts work.marc
    work.suppress_reindex
    work.save!
end

File.open( "005-works.yml" , "w") {|f| f.write(@list.to_yaml) }