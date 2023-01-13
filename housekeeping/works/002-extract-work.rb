require 'progress_bar'
require './housekeeping/works/functions'

pb = ProgressBar.new(Source.all.count)

@list = Array.new
@op = Array.new
@skipped = Array.new
@cmp_gnd_ids = Hash.new
@restriction = Array.new

def is_restricted(cmp_id, cat_id)
    cats = @restriction.select{|r| r[1] == cat_id}
    # not restricted if the catalogue is not in the list
    return false if cats.empty?

    cmps = @restriction.select{|r| r[0] == cmp_id}
    # restricted if the catalogue in the list but not the composer
    return true if cmps.empty? 

    # make sure we have a match
    return !cats.find{|r| r[0] == cmp_id}
end

def get_gnd_id(person)
    # look in cache first
    stored_id = @cmp_gnd_ids[person.id]
    return stored_id if stored_id
    # get it otherwise
    person.marc.load_source false
    person.marc.each_by_tag("024") do |t|
        t2 = t.fetch_first_by_tag("2")
        if t2 and t2.content and t2.content == "DNB"
            ta = t.fetch_first_by_tag("a")
            if ta and ta.content
                @cmp_gnd_ids[person.id] = ta.content
                return ta.content
            end
        end
    end
    nil
end

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

src_count = 0

# load the restriction list (cmp-id, cat-id) as CSV
@restriction = CSV.open("./housekeeping/works/002-restriction.csv").each.to_a

#Source.where(composer: "Bach, Johann Sebastian").find_in_batches do |batch|
#Source.where(composer: "Corelli, Arcangelo").find_in_batches do |batch|
#Source.where(composer: "Graupner, Christoph").find_in_batches do |batch|
Source.find_in_batches do |batch|

    batch.each do |s|

        pb.increment!

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

        title = nil
        scoring = nil
        extract = nil
        arr = nil
        
        # try to get the title (240)
        # Quartets
        node = s.marc.first_occurance("240", "a")
        title = node.content if node && node.content
        title = title.strip if title
        
        node = s.marc.first_occurance("240", "m")
        scoring = node.content if node && node.content
        scoring = scoring.strip if scoring
    
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

        node = s.marc.first_occurance("690", "0")
        cat_0 = node.content if node && node.content
        if is_restricted(id, cat_0)
            #puts "Skipping #{id}, #{cat_0}"
            next
        end

        node = s.marc.first_occurance("690", "a")
        cat_a = node.content if node && node.content
        cat_a = cat_a.strip if cat_a
        
        node = s.marc.first_occurance("690", "n")
        cat_n =  node.content if node && node.content
        #cat_n = node.content.gsub(/\/.*/,"") if node && node.content
        cat_n = cat_n.strip if cat_n

        # custom extraction
        cat_extract_id = "cat_extract_#{id}".to_s

        if respond_to?(cat_extract_id)
            cat_n = method(cat_extract_id).call(cat_n) if cat_n
        else
            cat_n = cat_extract(cat_n) if cat_n
        end

        # Skip catalogue with "deest" (without opus)
        next if !opus and cat_n and /^deest$/.match?(cat_n)

        src = Hash.new
        src['id'] = s.id 
        src['cmp'] = s.composer
        src['std_title'] = s.std_title

        item = Hash.new
        item['sources'] = Array.new
        item['cmp-id'] = id
        item['title'] = title if title
        #item['scoring'] = scoring if scoring
        #item['extract'] = extract if extract
        #item['arr'] = arr if arr
        item['opus'] = opus if opus
        item['cat_a'] = cat_a if cat_a
        item['cat_n'] = cat_n if cat_n  

        src_count += 1

        work_item = find_work_list(id, opus, cat_a, cat_n)
        if work_item
            work_item['sources'].append(src)
            next
        end

        item['sources'].append(src)
        @list.append(item)  

        w = Work.new
        new_marc = MarcWork.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/work/default.marc")))
        new_marc.load_source false # this will need to be fixed
        w.marc = new_marc

        w_100 = w.marc.first_occurance("100")
        w_100.destroy_yourself if w_100
        w_100 = s.marc.first_occurance("100").deep_copy
        if title
            w_100.add_at(MarcNode.new("work", "t", title, nil), 0)
        end
        w_100j = w_100.fetch_first_by_tag("j")
        w_100j.destroy_yourself if w_100j
        w_100.sort_alphabetically
        w.marc.root.add_at(w_100, w.marc.get_insert_position("100"))

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
        w.person = Person.find(id) rescue nil
        item['cmp-name'] = w.person ? w.person.full_name : "[missing]"
        gnd_id = w.person ? get_gnd_id(w.person) : nil
        if (gnd_id)
            item['cmp-gnd'] = gnd_id
        end
        w.suppress_reindex
        w.save!
        item['w-id'] = w.id
    end
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

puts "Sources grouped: #{src_count}"
puts "Opus processed: #{@op.size}"
puts "Opus skipped: #{@skipped.size}"

File.open( "002-opus.yml" , "w") {|f| f.write(@op.uniq.sort.to_yaml) }
File.open( "002-opus-skipped.yml" , "w") {|f| f.write(@skipped.to_yaml) }
File.open( "002-works.yml" , "w") {|f| f.write(@list.to_yaml) }
File.open("002-gnd-ids.txt", "w+") do |f|
    @cmp_gnd_ids.values.each { |element| f.puts(element) }
end
