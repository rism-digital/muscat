@data = 'Hello world!'


fields = {
"100": ["a"],
"245": ["a"],
"260": ["a", "b", "c"],
"300": ["a"],
"500": ["a"],
"505": ["a"],
"691": ["a", "n"],
"510": ["a", "c"],
"596": ["a", "b"],
"593": ["a"],
"700": [],
"710": [],
"852": ["a"],
"340": ["d"],
}


ids = File.readlines("04_children_mixed.txt")

sheet = RODF::Spreadsheet.new
table = sheet.table("MARC data")

header = table.row
header.cell("ID")
header.cell("created-at")
header.cell("images?")
fields.each do |tag, subtags|
    header.cell(tag.to_s + " " + subtags.join(", "))
end

pb = ProgressBar.new(ids.count)

ids.each do |i|
    s = Source.find(i)

    row = table.row

    row.cell(i)
    row.cell(s.created_at.to_s)
    row.cell(s.digital_objects.count)

    fields.each do |tag, subtags|
        values = []
        s.marc.each_by_tag(tag) do |t|

            if tag.to_s == "700" || tag.to_s == "710"
                rel = t.fetch_first_by_tag("4")
                if rel && rel.content
                    next if rel.content != "pbl" && rel.content != "prt"
                end
            end

            if subtags.empty?
                t.each do |tn|
                    next if !tn || !tn.content
                    values << "$#{tn.tag} #{tn.content}"
                end
            else
                subtags.each do |st|
                    t.fetch_all_by_tag(st).each do |tn|
                        next if !tn || !tn.content
                        values << "$#{tn.tag} #{tn.content}"
                    end
                end
            end
        end
        row.cell(values.join("\n"))
    end

    s = nil
    pb.increment!
end

sheet.write_to '04_children_mixed.ods'


=begin
RODF::Spreadsheet.file("my-spreadsheet.ods") do |sheet|
  sheet.table 'My first table from Ruby' do |table|
    table.row do |row|
      row.cell "ciao\npino\nmarittimo"
      row.cell "ciao"
      row.cell "ciao"
      row.cell "ciao"
      row.cell "ciao"
      row.cell "ciao"
      row.cell "ciao"
      row.cell "ciao"
      row.cell "ciao"
      row.cell "ciao"
      row.cell "ciao"
      row.cell "ciao"
      row.cell "ciao"
      row.cell "ciao"
      row.cell "ciao"
      row.cell "ciao"
    end
  end
end
=end