

def migrate_print(id, migrate_500)
    begin
        s = Source.find(id)
    rescue ActiveRecord::RecordNotFound
        puts "Could not find source #{s}"
        return
    end

    default_tags = ["035", "506", "541", "561", "591", "592", "599", "691", "852", "856"]
    default_relator_codes = {"700": ["fmo", "scr", "oth"], "710": ["fmo", "scr", "dpt", "oth"]}
    default_tags << "500" if migrate_500

    holding_conf = MarcConfigCache.get_configuration("holding")
    tag_index = {}
    move_tags = {}

    s.marc.all_tags.each do |tag|
        if !tag_index.include?(tag.tag.to_s)
        tag_index[tag.tag.to_s] = 0
        else
        tag_index[tag.tag.to_s] += 1
        end

        current_index = tag_index[tag.tag.to_s]

        next if tag.tag == "001"
        next if !holding_conf.has_tag? tag.tag

        if default_tags.include?(tag.tag)
            move_tags[tag.tag.to_s] ||= Array.new
            move_tags[tag.tag.to_s] << current_index
        end

        if default_relator_codes.keys.include?(tag.tag.to_sym)
        rel = tag.fetch_first_by_tag("4")
        if rel && rel.content && default_relator_codes[tag.tag.to_sym].include?(rel.content)
            move_tags[tag.tag.to_s] ||= Array.new
            move_tags[tag.tag.to_s] << current_index
        end
        end
    end

    holding_id = s.manuscript_to_print(move_tags)
    puts "Created holding #{holding_id}"
end

filename = ARGV[0]
migrate_500 = ARGV.count > 1 ? ARGV[1].downcase == "true" : true

if migrate_500
    puts "Convert list in #{filename} migrating 500 note to the holding record"
else
    puts "Convert list in #{filename} leaving 500 note in the bib record"
end

File.readlines(filename).each do |line|
    next if line.strip.empty?
    migrate_print(line.strip, migrate_500)
end

#list.each {|id| migrate_print(id)}