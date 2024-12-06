bookids = []

@sheet = RODF::Spreadsheet.new
@table = @sheet.table("HMI Book ID matches Identified")

# Header
row = @table.row
row.cell("InventoryItem")
row.cell('II Composer')
row.cell('II Title')
row.cell("Book ID")
row.cell("Identification status")

row.cell("Source")
row.cell("Source Composer")
row.cell("Source Title")

def result2row(result, ii, bookid, ident)
    row = @table.row

    row.cell(ii.id)
    row.cell(ii.composer)
    row.cell(ii.title.truncate(100))
    row.cell(bookid)
    row.cell(ident)

    row.cell(result.id)
    row.cell(result.composer)
    row.cell(result.title.truncate(100))

end

InventoryItem.all.each do |ii|

    ii.marc.each_by_tag("786") do |t|
        it = t.fetch_first_by_tag("i")
        # augh
        ident = it.content if it && it.content
        ident = "Possibly identified source" if !it || !it.content

        next if ident != "Identified source"

        tgs = t.fetch_all_by_tag("o")

        tgs.each do |to|
            next if !to || !to.content

            # try to sanitize this mess
            sanebook = to.content.gsub("RISM A/I", "")
                                 .gsub("RISM B/I", "")
                                 .gsub("RSIM A/I", "")
                                 .gsub("RIS/ A/I", "")
                                 .gsub("RISM/ A/I", "")
                                 .gsub("RiSM A/I", "")
                                 .gsub("RISM /", "")
                                 .gsub("RISM A/", "")
                                 .gsub("RISM B/VIII/1,", "")
                                 .gsub("RISM B/VIII/1", "")
                                 .gsub("RISM B/VIII.1", "")
                                 .gsub("RISM B/VI", "")
                                 .gsub("RISM", "")
                                 .gsub("B/I", "")
                                 .gsub("B/BB", "BB")
                                 .gsub("H/HH", "HH")
                                 .gsub("P/PP", "PP")
                                 .gsub("and", ";")
                                 .gsub("=", ";")
                                 .gsub(", ", "")
                                 .gsub(": ", "")
                                 .gsub("D 3523/DD 3523", "D 3523; DD 3523")
                                 .gsub("S 4296/SS 4296", "S 4296; SS 4296")
                                 .gsub("C 4171/CC 4171", "C 4171; CC 4171")
                                 .gsub("U 119/UU 119", "U 119; UU 119")
                                 .gsub("S 4296/SS 4296", "S 4296; SS 4296")
                                 .split(";").map{|b|b.strip}
            bookids += sanebook

            sanebook.each do |bookid|
                res = Source.solr_search do
                    with :bookid_string, bookid
                end
                res.results.each do |result|
                    result2row(result, ii, bookid, ident)
                end
            end
        end
    end

end

@sheet.write_to 'hmi_bookids_identified.ods'
#ap bookids