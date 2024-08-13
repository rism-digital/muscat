sheet = RODF::Spreadsheet.new
table = sheet.table("Lost 710")

sheet.style 'red-cell', family: :cell do |s|
    s.property :text, 'color' => '#ff0000'
  end

PaperTrail::Version.where(event: "Ch migration merged record").each do |v|
    
    very_old_source = v.reify
    very_old_source.marc.load_source false
    next if very_old_source.marc.by_tags("710").count < 1

    row = table.row
    row.cell(very_old_source.id)

    begin
        current_src = Source.find(very_old_source.id)
    rescue ActiveRecord::RecordNotFound
        puts "Source #{very_old_source.id} vas deleted"
        row.cell("deleted")
        next
    end

    current_src.marc.each_by_tag("710") do |t|
        the_a = t.fetch_first_by_tag("a").content rescue ""
        the_4 = t.fetch_first_by_tag("4").content rescue ""
        the_0 = t.fetch_first_by_tag("0").content rescue ""

        conc = [the_a, the_0, the_4].join("; ")
        row.cell conc, style: 'red-cell'
    end

    row.cell("") if current_src.marc.by_tags("710").count == 0

    very_old_source.marc.each_by_tag("710") do |t|
        the_a = t.fetch_first_by_tag("a").content rescue ""
        the_4 = t.fetch_first_by_tag("4").content rescue ""
        the_0 = t.fetch_first_by_tag("0").content rescue ""

        conc = [the_a, the_0, the_4].join("; ")
        row.cell(conc)
    end

end

sheet.write_to 'lost710.ods'
