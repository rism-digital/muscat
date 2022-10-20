Folder.all.each do |folder|
    folder.delete_date = Time.now + 6.months
    folder.save
end