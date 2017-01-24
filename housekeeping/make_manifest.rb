require 'awesome_print'
require 'iiif/presentation'
require 'yaml'

module Faraday
  module NestedParamsEncoder
    def self.escape(arg)
			#puts "NOTICE - UNESCAPED URL NestedParamsEncoder"
      arg
    end
  end
  module FlatParamsEncoder
    def self.escape(arg)
			#puts "NOTICE - UNESCAPED URL FlatParamsEncoder"
      arg
    end
  end
end

#IIF_PATH="http://d-lib.rism-ch.org/cgi-bin/iipsrv.fcgi?IIIF=/usr/local/images/ch/"
IIF_PATH="http://iiif.rism-ch.org/iiif/"

if ARGV[0].include?("yml")
  dirs  = YAML.load_file(ARGV[0])
else
  dirs = ARGV
end

dirs.keys.each do |dir|
  source = nil
  title = "Images for #{dir}"
  
  if dirs.is_a? Array
    images = Dir.entries(dir).select{|x| x.match("tif") }.sort
  else
    images = dirs[dir].sort
  end
  
  if images.length == 0
    puts "no images in #{dir}"
  end
  
  print "Attempting #{dir}... "
  
  # If running in Rails get some ms info
  if defined?(Rails)
    source = Source.find(dir)
    title = source.title
  end
  
  # Create the base manifest file
  seed = {
      '@id' => "http://iif.rism-ch.org/#{dir}.json",
      'label' => title
  }
  # Any options you add are added to the object
  manifest = IIIF::Presentation::Manifest.new(seed)
  sequence = IIIF::Presentation::Sequence.new
  manifest.sequences << sequence
  
  images.each do |image_name|
    canvas = IIIF::Presentation::Canvas.new()
    canvas['@id'] = "#{dir}/#{image_name}"
    canvas.label = image_name
    
    image_url = IIF_PATH + dir + "/" + image_name
    
    image = IIIF::Presentation::Annotation.new
    image["on"] = canvas['@id']
    image_resource = IIIF::Presentation::ImageResource.create_image_api_image_resource(service_id: image_url)
    image.resource = image_resource
    
    canvas.width = image.resource['width']
    canvas.height = image.resource['height']
    
    canvas.images << image
    sequence.canvases << canvas
  end
  
  #puts manifest.to_json(pretty: true)
  File.write(dir + '.json', manifest.to_json(pretty: true))
  puts "Wrote #{dir}.json"
  
  if source
    marc = source.marc
    marc.load_source true
    
    if marc.by_tags("856").length == 0
    
      new_tag = MarcNode.new("source", "856", "", "##")
      new_tag.add_at(MarcNode.new("source", "x", "IIIF", nil), 0)
      new_tag.add_at(MarcNode.new("source", "u", "http://iiif.rism-ch.org/manifest/#{dir}.json", nil), 0)

      pi = marc.get_insert_position("856")
      marc.root.children.insert(pi, new_tag)
    
      source.save!
    else
      puts "Source #{source.id} already has 856, not overwriting"
    end
  end

end