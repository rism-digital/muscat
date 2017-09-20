## Make the JSON manifest for the images
## it reads a yml file with the image list
## so the images do not need to be stored on the same system
## and the other system does not need a rails installation
## The YAML is simply a listing of the files + the record in
## for example this script:

# require 'yaml'
#
# out = {}
# ARGV.each do |dir|
#   images = Dir.entries(dir).select{|x| x.match("tif") }.sort
#   out[dir] = images
# end

# File.write("dirs.yml", out.to_yaml)
#####

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
    id = dir
    toks = dir.split("-")
    ## if it contains the -xxx just get the ID
    id = toks[0] if toks != [dir]
    source = Source.find(dir)
    title = source.title
  end
  
  # Create the base manifest file
  seed = {
      '@id' => "http://iiif.rism-ch.org/manifest/#{dir}.json",
      'label' => title,
      'related' => "http://www.rism-ch.org/catalog/#{dir}"
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
    ## Uncomment these two prints to see the progress of the HTTP reqs.
    #print "-"
    image_resource = IIIF::Presentation::ImageResource.create_image_api_image_resource(service_id: image_url)
    #print "."
    image.resource = image_resource
    
    canvas.width = image.resource['width']
    canvas.height = image.resource['height']
    
    canvas.images << image
    sequence.canvases << canvas
    
    # Some obnoxious servers block you after some requests
    # may also be a server/firewall combination
    # comment this if you are positive your server works
    sleep 0.1
  end
  
  #puts manifest.to_json(pretty: true)
  File.write(dir + '.json', manifest.to_json(pretty: true))
  puts "Wrote #{dir}.json"
  
  if source
    marc = source.marc
    marc.load_source true

    # The source can contain more than one 856
    # as some sources have more image groups
    # -01 -02 etc
    new_tag = MarcNode.new("source", "856", "", "##")
    new_tag.add_at(MarcNode.new("source", "x", "IIIF", nil), 0)
    new_tag.add_at(MarcNode.new("source", "u", "http://iiif.rism-ch.org/manifest/#{dir}.json", nil), 0)

    pi = marc.get_insert_position("856")
    marc.root.children.insert(pi, new_tag)
  
    source.save!
  end

end