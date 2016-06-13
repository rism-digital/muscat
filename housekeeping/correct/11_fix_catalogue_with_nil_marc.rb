require 'progress_bar'

catalogue_with_nil_marc = Catalogue.where(:marc => nil)

pb = ProgressBar.new(catalogue_with_nil_marc.size)
catalogue_with_nil_marc.each do |record|
  new_marc = MarcCatalogue.new(File.read("#{Rails.root}/config/marc/#{RISM::MARC}/catalogue/default.marc"))
  new_marc.load_source false # this will need to be fixed
  new_240 = MarcNode.new(Catalogue, "240", "", "10")
  ip = new_marc.get_insert_position("240")
  count=0
  new_240.add_at(MarcNode.new(Catalogue, "a", record.name, nil), count)
  new_marc.root.children.insert(ip, new_240)
  record.marc = new_marc
  record.description = record.name
  record.name = nil
  record.save
  pb.increment!

end


