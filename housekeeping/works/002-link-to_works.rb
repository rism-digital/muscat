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

def link_work_for_cat(item, src, composer_id, cat_tag, src_ref)
    s_690_0 = cat_tag.fetch_first_by_tag("0")
    return if (!s_690_0 || !s_690_0.content)
    # not the desired catalogue
    if (s_690_0.content.to_i != item[:catalogue_id])
        #puts "#{node.content} | #{item[:catalogue_id]}"
        return
    end

    s_690a = cat_tag.fetch_first_by_tag("a")
    cat_a = s_690a.content if s_690a && s_690a.content
    cat_a = cat_a.strip if cat_a

    s_690n = cat_tag.fetch_first_by_tag("n")
    cat_n = s_690n.content if s_690n && s_690n.content
    cat_n = cat_n.strip if cat_n

    # custom extraction method
    if item[:catalogue_extraction] 
        cat_n = method(item[:catalogue_extraction]).call(cat_n) if cat_n
    else
        cat_n = cat_extract(cat_n) if cat_n
    end

    # Skip catalogue with "deest" (without opus)
    return if !cat_n || /^deest$/.match?(cat_n)

    work_item = find_work_list_db(composer_id, nil, cat_a, cat_n)
    return if !work_item

    work_id = work_item.id
    @work_sources[work_id] = Array.new if !@work_sources[work_id]

    new_item = Hash.new
    new_item['sources'] = Array.new
    new_item['cmp-id'] = composer_id
    new_item['cat_a'] = cat_a if cat_a
    new_item['cat_n'] = cat_n if cat_n  

    @src_count += 1

    @work_sources[work_id].append(src_ref)
end

#################################################################################
# create a work from a source record

def link_work_for(item, src)
    # Check if the source has been linked already
    return if (SourceWorkRelation.find_by_source_id(src.id))

    src.marc.load_source false

    spr = SourcePersonRelation.find_by(source_id: src.id, marc_tag: "100")
    return if !spr
    composer_id = spr.person_id

    # skip sources witout composer or by Anonymus or by Compilations
    return if !composer_id or composer_id == '30004985' or composer_id == '30009236'

    subheading = nil
    arrangement = nil
    
    node = src.marc.first_occurance("240", "k")
    subheading = node.content if node && node.content
    subheading = subheading.strip if subheading
    
    node = src.marc.first_occurance("240", "o")
    arrangement = node.content if node && node.content
    arrangement = arrangement.strip if arrangement

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

    src.marc.each_by_tag("690") do |tag|
        link_work_for_cat(item, src, composer_id, tag, src_ref)
    end

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
    process_sources_for(catalogue.transform_keys(&:to_sym), "link_work_for")
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
