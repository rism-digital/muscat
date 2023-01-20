require 'progress_bar'
require './housekeeping/works/functions'

#################################################################################
# add a link 930 link to a work (not used)

def add_link_to_work(source, work, work_item)
    node = MarcNode.new("work", "856", "", "##")
    node.add_at(MarcNode.new("work", "u", "/admin/sources/#{work_item['id']}", nil), 0)
    node.add_at(MarcNode.new("work", "z", "#{work_item['cmp']}: #{work_item['std_title']}", nil), 0)
    node.sort_alphabetically
    work.marc.root.children.insert(work.marc.get_insert_position("856"), node)
end

def add_standard_term(work, src)
    added = 0
    src.marc.each_by_tag("650") do |tag|
        w_380 = tag.deep_copy
        w_380.tag = "380"
        work.marc.root.add_at(w_380, work.marc.get_insert_position("380"))
        added += 1
        #puts work.marc.find_duplicates(["380"])
    end
    return if added == 0
    work.save
end

#################################################################################
# create a work from a source record

def create_work(src, composer_id, opus, cat_a, cat_n)
    w = Work.new
    new_marc = MarcWork.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/work/default.marc")))
    new_marc.load_source false # this will need to be fixed
    w.marc = new_marc

    w_100 = w.marc.first_occurance("100")
    w_100.destroy_yourself if w_100
    w_100 = src.marc.first_occurance("100").deep_copy
    # remove j
    w_100j = w_100.fetch_first_by_tag("j")
    w_100j.destroy_yourself if w_100j
    w.marc.root.add_at(w_100, w.marc.get_insert_position("100"))

    w_130 = w.marc.first_occurance("130")
    w_130.destroy_yourself if w_130
    w_130 = src.marc.first_occurance("240").deep_copy
    w_130.tag = "130"
    # we keep only $a $m (scoring) and $m (key) - remove $k and $o
    w_130k = w_130.fetch_first_by_tag("k")
    w_130k.destroy_yourself if w_130k
    w_130o = w_130.fetch_first_by_tag("o")
    w_130o.destroy_yourself if w_130o
    w_130.sort_alphabetically
    w.marc.root.add_at(w_130, w.marc.get_insert_position("130"))

    if opus
        w_opus = src.marc.first_occurance("383").deep_copy
        w.marc.root.add_at(w_opus, w.marc.get_insert_position("383"))
        # replace the $b with the cleaned-up version 
        w_opus_b = w_opus.fetch_first_by_tag("b")
        w_opus_b.content = opus
    end

    if cat_n and cat_a
        w_cat = src.marc.first_occurance("690").deep_copy
        w.marc.root.add_at(w_cat, w.marc.get_insert_position("690"))
        # replace $n with the cleaned-up version
        w_cat_n = w_cat.fetch_first_by_tag("n")
        w_cat_n.content = cat_n
    end 

    w_667 = MarcNode.new("work", "667", "", "##")
    w_667.add_at(MarcNode.new("work", "a", "Title imported from #{src.id}", nil), 0)
    w.marc.root.add_at(w_667, w.marc.get_insert_position("667"))

    w.person = Person.find(composer_id) rescue nil
    w.suppress_reindex
    w.save!
    w
end

def extract_work_for(item, src)
    # Check if the source has been extracted already
    return if (SourceWorkRelation.find_by_source_id(src.id))

    src.marc.load_source false

    spr = SourcePersonRelation.find_by(source_id: src.id, marc_tag: "100")
    return if !spr
    composer_id = spr.person_id

    # skip sources witout composer or by Anonymus or by Compilations
    return if !composer_id or composer_id == '30004985' or composer_id == '30009236'

    count690 = 0
    src.marc.each_by_tag("690") {|t| count690 += 1}
    count383 = 0
    src.marc.each_by_tag("383") {|t| count383 += 1}

    if count690 > 1
        return
        #puts "ts690 https://muscat.rism.info/admin/sources/#{src.id} #{ts690.size}"
    end
    if count383 > 1 
        return
        #puts "ts383 https://muscat.rism.info/admin/sources/#{src.id} #{ts383.size}"
    end
    if count690 == 0 && count383 == 0
        return
    end

    node = src.marc.first_occurance("690", "0")
    return if (!node || !node.content)
    # not the desired catalogue
    if (node.content.to_i != item[:catalogue_id])
        #puts "#{node.content} | #{item[:catalogue_id]}"
        return
    end

    title = nil
    scoring = nil
    subheading = nil
    arrangement = nil
    
    # try to get the title (240)
    # Quartets
    node = src.marc.first_occurance("240", "a")
    title = node.content if node && node.content
    title = title.strip if title

    node = src.marc.first_occurance("240", "k")
    subheading = node.content if node && node.content
    subheading = subheading.strip if subheading
    
    node = src.marc.first_occurance("240", "o")
    arrangement = node.content if node && node.content
    arrangement = arrangement.strip if arrangement

    node = src.marc.first_occurance("383", "b")
    opus = node.content if node && node.content
    opus = opus.strip if opus

    #puts "#{src.id} #{opus}"
    if opus
        opus_orig = opus
        opus = format_opus(opus)
        if (!check_opus(opus))
            #puts "#{src.id} #{opus}"
            @skipped << {src.id => [opus_orig, opus]}
            return
        end
        @op << opus
    end

    node = src.marc.first_occurance("690", "a")
    cat_a = node.content if node && node.content
    cat_a = cat_a.strip if cat_a
    
    node = src.marc.first_occurance("690", "n")
    cat_n =  node.content if node && node.content
    #cat_n = node.content.gsub(/\/.*/,"") if node && node.content
    cat_n = cat_n.strip if cat_n

    # custom extraction method
    if item[:catalogue_extraction] 
        cat_n = method(item[:catalogue_extraction]).call(cat_n) if cat_n
    else
        cat_n = cat_extract(cat_n) if cat_n
    end

    # Skip catalogue with "deest" (without opus)
    return if !opus and cat_n and /^deest$/.match?(cat_n)

    src_ref = Hash.new
    src_ref['id'] = src.id 
    src_ref['cmp'] = src.composer
    src_ref['std_title'] = src.std_title
    src_ref['relator_codes'] = Array.new
    if (check_arr(arrangement))
        src_ref['relator_codes'].append(arrangement)
    else
        @arrangement_err.append("https://muscat.rism.info/admin/sources/#{src.id}") if arrangement
    end
    if (check_subheading(subheading))
        src_ref['relator_codes'].append(subheading)
    else
        @subheading_err.append("https://muscat.rism.info/admin/sources/#{src.id}") if subheading
    end
    src_ref['relator_codes'].append('') if src_ref['relator_codes'].empty?

    work_item = find_work_list_db(composer_id, opus, cat_a, cat_n)
    work_item =  create_work(src, composer_id, opus, cat_a, cat_n) if !work_item

    if (!arrangement && !subheading)
        #add_standard_term(work_item, src)
    end

    work_id = work_item.id
    @work_sources[work_id] = Array.new if !@work_sources[work_id]

    new_item = Hash.new
    new_item['sources'] = Array.new
    new_item['cmp-id'] = composer_id
    new_item['title'] = title if title
    new_item['opus'] = opus if opus
    new_item['cat_a'] = cat_a if cat_a
    new_item['cat_n'] = cat_n if cat_n  

    @src_count += 1

    @work_sources[work_id].append(src_ref)
end

#################################################################################
# Main

if ARGV.length < 1
    puts "Too few arguments"
    exit
end

@work_sources = Hash.new
@op = Array.new
@skipped = Array.new
@subheading_err = Array.new
@arrangement_err = Array.new
@src_count = 0

catalogue_file = ARGV[0]
catalogues = YAML.load(File.read("#{catalogue_file}.yml"))
puts catalogues

catalogues.each do |catalogue|
    process_works_for(catalogue.transform_keys(&:to_sym), "extract_work_for")
end

@work_sources.each do |work_id, sources|
    sources.each do |s|
        s['relator_codes'].each do |code|
            r = SourceWorkRelation.new(source_id: s['id'], work_id: work_id)
            r.relator_code = code.downcase if !code.empty?
            r.save
        end
    end
end

puts "Sources grouped: #{@src_count}"
puts "Opus processed: #{@op.size}"
puts "Opus skipped: #{@skipped.size}"
puts "Invalid arrangements: #{@arrangement_err.size}"
puts "Invalid subheadings: #{@subheading_err.size}"

File.open( "#{catalogue_file}-opus.yml" , "w") {|f| f.write(@op.uniq.sort.to_yaml) }
File.open( "#{catalogue_file}-opus-skipped.yml" , "w") {|f| f.write(@skipped.to_yaml) }
File.open( "#{catalogue_file}-arrangement-err.yml" , "w") {|f| f.write(@arrangement_err.to_yaml) }
File.open( "#{catalogue_file}-subheading-err.yml" , "w") {|f| f.write(@subheading_err.to_yaml) }
#File.open( "#{catalogue_file}_works.yml" , "w") {|f| f.write(@list.to_yaml) }
