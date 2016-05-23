require 'progress_bar'

pb = ProgressBar.new(Source.all.count)

u = {}

Source.all.each do |s|
  #s = Source.find(s1)
  @editor_profile = EditorConfiguration.get_default_layout s
	
  s.marc.load_source false
  
  tag_names = Array.new
  @editor_profile.each_tag_not_in_layout s do |tag|
    #$stderr.puts "#{s.id} #{tag} - #{s.get_record_type}"
    if !u.include? tag
      u[tag] = []
    end
    u[tag] << "#{s.id} - #{s.get_record_type}"
  end

  pb.increment!
end

u.each do |k, v|
  puts k.red
  v.first(5).each do |p|
    puts "\t#{p.to_s.yellow}"
  end
  puts "\t...#{v.count - 5} more".green if v.count > 5
  
end