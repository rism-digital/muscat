  def parse_comment(comment)
    matches = comment.scan(/@[A-Za-z0-9_-]*/)
    [] if matches.empty?
    bong = []
    
    user_ids = matches.each.map do |name|
        begin
            User.find_by_name(name.gsub("@", "").gsub("_", " ")).id
        rescue
            bong << name
        end
    end
    bong.compact
  end


sheet = RODF::Spreadsheet.new
table = sheet.table("Coments")

header = table.row
header.cell("Comment ID")
header.cell("Not found names")
header.cell("Comment body")
header.cell("Item ID")
header.cell("Item link")

ActiveAdmin::Comment.all.each do |c|



    reg = parse_comment(c.body)
    

    if !reg.empty?
        row = table.row
        puts c.id
        row.cell(c.id)
        row.cell(reg.join(", "))
        row.cell(c.body)
        row.cell(c.resource_id)
        row.cell("https://muscat.rism.info/admin/#{c.resource_type.downcase.pluralize}/#{c.resource_id}")
    end

end

sheet.write_to 'Undelivered_comments.ods'
