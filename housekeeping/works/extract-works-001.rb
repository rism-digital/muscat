require 'progress_bar'
require './housekeeping/works/functions'

@list = Array.new
@op = Array.new
@skipped = Array.new

def find_work_list(composer_id, opus, cat_a, cat_n)
    w_opus = nil
    w_cat = nil
    w_both = nil
    # we have both an opus and a catalogue number
    if opus and cat_a and cat_n
        w_both = @list.find{|w| w["opus"] == opus and w["cat_a"] == cat_a and w["cat_n"] == cat_n and w["cmp-id"] == composer_id}
    end
    # return the one matching both if any
    return w_both if w_both

    if opus
        w_opus = @list.find{|w| w["opus"] == opus and w["cmp-id"] == composer_id}
    end
    if cat_a and cat_n
        w_cat = @list.find{|w| w["cat_a"] == cat_a and w["cat_n"] == cat_n and w["cmp-id"] == composer_id}
    end
    # maybe we need to log cases where opus and catalogue mis-match
    #if w_opus and w_cat and w_opus['w-id'] != w_cat['w-id']
    #    #puts "Discrepancy #{w_opus['cmp']}: #{w_opus['title']} #{w_opus['opus']} #{w_opus['cat_n']} | #{w_cat['opus']} | #{w_cat['cat_n']}"
    #end
    # give prececence to catalogue number
    return w_cat ? w_cat : w_opus
end

def add_link_to_work(source, work, work_item)
    node = MarcNode.new("work", "856", "", "##")
    node.add_at(MarcNode.new("work", "u", "/admin/sources/#{work_item['id']}", nil), 0)
    node.add_at(MarcNode.new("work", "z", "#{work_item['cmp']}: #{work_item['std_title']}", nil), 0)
    node.sort_alphabetically
    work.marc.root.children.insert(work.marc.get_insert_position("856"), node)
end

if ARGV.length < 1
    puts "Too few arguments"
    exit
end

@src_count = 0

catalogue_file = ARGV[0]
catalogues = YAML.load(File.read(catalogue_file))
puts catalogues


def extract_works_for(item)
    puts "Extract works for: #{item[:composer_name]} (#{item[:composer_id]})"
    pb = ProgressBar.new(SourcePersonRelation.where(person_id: item[:composer_id], marc_tag: "100").count)

    SourcePersonRelation.where(person_id: item[:composer_id], marc_tag: "100").find_in_batches do |batch|
        batch.each do |spr|
            pb.increment!
            
            s = spr.source
            s.marc.load_source false

            id = nil
            s.marc.each_by_tag("100") do |t|
                t0 = t.fetch_first_by_tag("0")
                if t0 and t0.content
                    id = t0.content
                end
                break
            end
            # skip sources witout composer or by Anonymus or by Compilations
            next if !id or id == '30004985' or id == '30009236'
    
            count690 = 0
            s.marc.each_by_tag("690") {|t| count690 += 1}
            count383 = 0
            s.marc.each_by_tag("383") {|t| count383 += 1}
    
            if count690 > 1
                next
                #puts "ts690 https://muscat.rism.info/admin/sources/#{s.id} #{ts690.size}"
            end
            if count383 > 1 
                next
                #puts "ts383 https://muscat.rism.info/admin/sources/#{s.id} #{ts383.size}"
            end
            if count690 == 0 && count383 == 0
                next
            end

            node = s.marc.first_occurance("690", "0")
            if (node && node.content && node.content.to_i != item[:catalogue_id])
                #puts "#{node.content} | #{item[:catalogue_id]}"
                next
            end
    
            title = nil
            scoring = nil
            extract = nil
            arr = nil
            
            # try to get the title (240)
            # Quartets
            node = s.marc.first_occurance("240", "a")
            title = node.content if node && node.content
            title = title.strip if title
        
            node = s.marc.first_occurance("240", "k")
            extract = node.content if node && node.content
            extract = extract.strip if extract
            
            node = s.marc.first_occurance("240", "o")
            arr = node.content if node && node.content
            arr = arr.strip if arr
        
            node = s.marc.first_occurance("383", "b")
            opus = node.content if node && node.content
            opus = opus.strip if opus
    
            #puts "#{s.id} #{opus}"
            if opus
                opus_orig = opus
                opus = format_opus(opus)
                if (!check_opus(opus))
                    #puts "#{s.id} #{opus}"
                    @skipped << {s.id => [opus_orig, opus]}
                    next
                end
                @op << opus
            end
    
            node = s.marc.first_occurance("690", "a")
            cat_a = node.content if node && node.content
            cat_a = cat_a.strip if cat_a
            
            node = s.marc.first_occurance("690", "n")
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
            next if !opus and cat_n and /^deest$/.match?(cat_n)
    
            src = Hash.new
            src['id'] = s.id 
            src['cmp'] = s.composer
            src['std_title'] = s.std_title
    
            new_item = Hash.new
            new_item['sources'] = Array.new
            new_item['cmp-id'] = id
            new_item['title'] = title if title
            #new_item['scoring'] = scoring if scoring
            #new_item['extract'] = extract if extract
            #new_item['arr'] = arr if arr
            new_item['opus'] = opus if opus
            new_item['cat_a'] = cat_a if cat_a
            new_item['cat_n'] = cat_n if cat_n  
    
            @src_count += 1
    
            work_item = find_work_list(id, opus, cat_a, cat_n)
            if work_item
                work_item['sources'].append(src)
                next
            end
    
            new_item['sources'].append(src)
            @list.append(new_item)  
    
            w = Work.new
            new_marc = MarcWork.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/work/default.marc")))
            new_marc.load_source false # this will need to be fixed
            w.marc = new_marc
    
            w_100 = w.marc.first_occurance("100")
            w_100.destroy_yourself if w_100
            w_100 = s.marc.first_occurance("100").deep_copy
            w.marc.root.add_at(w_100, w.marc.get_insert_position("100"))

            w_130 = w.marc.first_occurance("130")
            w_130.destroy_yourself if w_130
            w_130 = s.marc.first_occurance("240").deep_copy
            w_130.tag = "130"
            # we keep only $a $m (scoring) and $m (key) - remove $k and $o
            w_130k = w_130.fetch_first_by_tag("k")
            w_130k.destroy_yourself if w_130k
            w_130o = w_130.fetch_first_by_tag("o")
            w_130o.destroy_yourself if w_130o
            w_130.sort_alphabetically
            w.marc.root.add_at(w_130, w.marc.get_insert_position("130"))
    
            if opus
                w_opus = s.marc.first_occurance("383").deep_copy
                w.marc.root.add_at(w_opus, w.marc.get_insert_position("383"))
                # replace the $b with the cleaned-up version 
                w_opus_b = w_opus.fetch_first_by_tag("b")
                w_opus_b.content = opus
            end

            if cat_n and cat_a
                w_cat = s.marc.first_occurance("690").deep_copy
                w.marc.root.add_at(w_cat, w.marc.get_insert_position("690"))
                # replace $n with the cleaned-up version
                w_cat_n = w_cat.fetch_first_by_tag("n")
                w_cat_n.content = cat_n
            end 

            w_667 = MarcNode.new("work", "667", "", "##")
            w_667.add_at(MarcNode.new("work", "a", "Title imported from #{s.id}", nil), 0)
            w.marc.root.add_at(w_667, w.marc.get_insert_position("667"))

            w.person = Person.find(id) rescue nil
            w.suppress_reindex
            w.save!
            new_item['w-id'] = w.id
        end
    end
end

catalogues.each do |catalogue|
    extract_works_for(catalogue.transform_keys(&:to_sym))
end

@list.each do |item|
    work = Work.find(item['w-id'])
    work.marc.load_source false
    item['sources'].each do |s|
        node = MarcNode.new("work", "856", "", "##")
        node.add_at(MarcNode.new("work", "u", "/admin/sources/#{s['id']}", nil), 0)
        node.add_at(MarcNode.new("work", "z", "#{s['cmp']}: #{s['std_title']}", nil), 0)
        node.sort_alphabetically
        work.marc.root.add_at(node, work.marc.get_insert_position("856"))
    end
    work.suppress_reindex
    work.save!
end

puts "Sources grouped: #{@src_count}"
puts "Opus processed: #{@op.size}"
puts "Opus skipped: #{@skipped.size}"

File.open( "opus.yml" , "w") {|f| f.write(@op.uniq.sort.to_yaml) }
File.open( "opus-skipped.yml" , "w") {|f| f.write(@skipped.to_yaml) }
File.open( "works.yml" , "w") {|f| f.write(@list.to_yaml) }
