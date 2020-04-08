
puts "\u001Bc"

count = 1
Source.where("lib_siglum LIKE '%CH%'").each do |s|
    #puts s.id
    puts "\033[0;0H#{sprintf("%07d", count)}"
    s.reindex
    count += 1
end