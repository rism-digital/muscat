Folder.all.each do |folder|
    folder.delete_date = Time.now + 3.month
    folder.save
end