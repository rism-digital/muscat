
collection_ms = {}
by_id = {}
subentry = {}

def untangle(h, table)
    h.each do |s, v|
        #next if v.count == 1
        row = table.row
        row.cell(s)
        v.each do |r|
        
            r.each do |i|
                row.cell(i)
            end
    
            #record = r.join("\t")
            #print "#{s}\t#{record}\t"
    
        end
        #puts
    end
end

def untangle_per_table(h, sheet)
    h.each do |s, v|
        next if v.count == 1
        table = sheet.table(s)
        
        v.each do |r|
            row = table.row
            r.each do |i|
                row.cell(i)
            end
    
            #record = r.join("\t")
            #print "#{s}\t#{record}\t"
    
        end
        #puts
    end
end

def untangle_with_color(h, by_id, table)
    h.each do |s, v|
        #next if v.count == 1
        last_parent = nil

        v.each do |r|
            parent = by_id[r[7]]

            # Create an entry for the parent
            if last_parent != parent[0]
                row = table.row
                color = parent[3] == "ICCU" ? "coll-iccu" : "coll-rism"
                parent.each do |i|
                    row.cell(i, style: color)
                end
                last_parent = parent[0]
            end

            row = table.row
            color = r[3] == "ICCU" ? "iccu" : "rism"
            r.each do |i|
                row.cell(i, style: color)
            end
    
            #record = r.join("\t")
            #print "#{s}\t#{record}\t"
    
        end
        #puts
    end
end

def is_iccu?(s)
    s.marc.each_by_tag("856") do |t|
        t.fetch_all_by_tag("u").each do|tt|
            return true if tt.content.include? "http://id.sbn.it/bid/"
        end
    end
    false
end

# Transform selfmarks in the form
# 1@4 and remove what is after @
def simple_strip(str)
    return str.split(/\W+/).join(' ').downcase.strip.split(" ").first
end

# More complex stuff
# Nodeda.Something 234.5@3
# Always strip the stuff after @
def strip_at_and_punct(str)
    return str.sub(/@\d+\z/, "").split(/\W+/).join(' ').downcase.strip
end

if ARGV.count < 1
    puts "Please give a siglum"
    exit
end

siglum = ARGV[0]


Source.by_siglum(siglum).each do |s|
    next if s.shelf_mark.empty?

    cleaned = strip_at_and_punct(s.shelf_mark)
    #cleaned = simple_strip s.shelf_mark

    #puts "#{cleaned}\t#{s.id}"
   # all[cleaned] |= []
    #all[cleaned] << s.id

    pub_status = I18n.t('status_codes.' + s.wf_stage.to_s)
    record_type = I18n.t('record_types_codes.' + s.record_type.to_s)
    iccu = is_iccu?(s) ? "ICCU" : "RISM"

    entry = [s.id, pub_status, record_type, iccu, s.composer, s.title, s.shelf_mark, s.parent_source&.id]



    if !s.parent_source
        (collection_ms[cleaned] ||= []) << entry
        #(subentry[cleaned] ||= []) << entry if s.record_type == 1 # put the collections with the children

        # save all of them flat
        by_id[s.id] = entry
    else
        (subentry[cleaned] ||= []) << entry
    end
end

sheet = RODF::Spreadsheet.new

sheet.style 'coll-iccu', family: :cell do |s|
    s.property :text, 'font-weight' => 'bold'#, 'color' => '#ff0000'
    s.property :cell, 'background-color' => "#e8d3d3"
end

sheet.style 'coll-rism', family: :cell do |s|
    s.property :text, 'font-weight' => 'bold'
    s.property :cell, 'background-color' => "#e8e1d3"
end

sheet.style 'iccu', family: :cell do |s|
    s.property :cell, 'background-color' => "#aabdaa"
end

sheet.style 'rism', family: :cell do |s|
    s.property :cell, 'background-color' => "#b9dbeb"
end

table = sheet.table("Parents #{siglum}")

untangle(collection_ms, table)

#table = sheet.table("Subs #{siglum}")

# Create one sheet per collection
#untangle_per_table(subentry, sheet)

table = sheet.table("Subs #{siglum}")
untangle_with_color(subentry, by_id, table)

sheet.write_to "duplicates_#{siglum}.ods"