require 'progress_bar'

publication_with_nil_marc = Publication.where(:marc => nil)

pb = ProgressBar.new(publication_with_nil_marc.size)
publication_with_nil_marc.each do |record|
  new_marc = MarcPublication.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/publication/default.marc")))
  new_marc.load_source false # this will need to be fixed
  new_240 = MarcNode.new(Publication, "240", "", "10")
  ip = new_marc.get_insert_position("240")
  count=0
  new_240.add_at(MarcNode.new(Publication, "a", record.name, nil), count)
  new_marc.root.children.insert(ip, new_240)
  record.marc = new_marc
  record.description = record.name
  record.name = nil
  record.save
  pb.increment!

end


