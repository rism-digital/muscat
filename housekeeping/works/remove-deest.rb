require 'progress_bar'

@list = YAML::load(File.read("./works.yml"))

pb = ProgressBar.new(@list.size)

deest = Array.new

@list.each do |item|
    pb.increment!
    if !item['opus'] and item['cat_n'] and /^deest$/.match?(item['cat_n'])
        deest << item
        #work = Work.find(item['w-id'])
        #work.destroy
    end
end

puts "#{deest.size} 'deest' items removed"
@list -= deest

File.open( "works-deleted.yml" , "w") {|f| f.write(@list.to_yaml) }