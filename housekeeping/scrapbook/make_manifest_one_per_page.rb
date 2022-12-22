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

IIF_PATH="http://d-lib.rism-ch.org/cgi-bin/iipsrv.fcgi?IIIF=/usr/local/images/raw/naples/"
#IIF_PATH="https://iiif.rism-ch.org/iiif/"

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
    
  # Create the base manifest file
  seed = {
      '@id' => "https://iiif.rism-ch.org/manifest/#{dir}.json",
      'label' => title,
      'related' => "http://www.rism-ch.org/catalog/#{dir}"
  }

  
  images.each do |image_name|
    # Any options you add are added to the object
    manifest = IIIF::Presentation::Manifest.new(seed)
    sequence = IIIF::Presentation::Sequence.new
    manifest.sequences << sequence

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

      #puts manifest.to_json(pretty: true)
    File.write(dir + '_' + image_name + '.json', manifest.to_json(pretty: true))
    puts "Wrote #{dir}.json"
  end
  

  


end