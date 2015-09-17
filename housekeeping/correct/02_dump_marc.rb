File.open("marc_dump.txt", 'w') do |file|

  Source.find_each do |s|
    file.write(s.marc_source)
    file.write("\n")
  end

end
