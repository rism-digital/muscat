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
# Should not have a trailing slash!
IIIF_PATH="https://iiif.rism.digital"

options = {}
oparser = nil
OptionParser.new do |opts|
  opts.banner = "Usage: make_manifest.rb [options] file"

  opts.on("-z", "--banner [BANNER]", "Banner for 856 $z") do |b|
    options[:banner] = b
  end

  opts.on("-x", "--type [TYPE]", "Document type 856 $x") do |b|
    options[:type] = b
  end

  opts.on("-d", "--no-create", "Do not add 856 to records") do |b|
    options[:nocreate] = b
  end

  opts.on("-f", "--force", "Force overwrite of already created manifests") do |b|
    options[:force] = b
  end

  opts.on("-p", "--path", "Set IIIF server URL path") do |b|
    options[:path] = b
  end

  opts.on("-r", "--no-reindex", "Do not reindex the sources") do |b|
    options[:noreindex] = b
  end

  opts.on("-o", "--only-add", "Do not create the manifests, only add the 856") do |b|
    options[:onlyadd] = b
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

  oparser = opts
end.parse!

if ARGV.empty?
  #puts "Usage: make_manifest.rb [options] dirs.yml"
  puts "Please specify a direcory listing file"
  puts oparser
  exit
end

if options.include?(:onlyadd) && options.include?(:nocreate)
  puts "-d and -o cannot be used together"
  puts oparser
  exit
end

options[:type] = "IIIF" if !options.include?(:type)
options[:banner] = "Digital Object" if !options.include?(:banner)
IIIF_PATH = options[:path] if options.include?(:path)

if ARGV.first.include?("yml")
  dirs  = YAML.load_file(ARGV.first)
else
  dirs = ARGV
end

puts "Creating manifests for #{ARGV.first}"
puts "Update 856 in record: #{ !(options.include?(:nocreate) && !options[:nocreate])}"
puts "Banner 856$z: #{options[:banner]}"
puts "Type 856$x #{options[:type]}"
puts "URL path: #{IIIF_PATH}"
puts "Force manifest creation: #{ options.include?(:force) && options[:force] == true}"
puts "Skip manifest creation: #{ options.include?(:onlyadd) && options[:onlyadd] == true}"


dirs.keys.each do |dir|

  db_element = nil
  title = "Images for #{dir}"
  
  if dirs.is_a? Array
    images = Dir.entries(dir).select{|x| x.match("tif") }.sort
  else
    images = dirs[dir].sort
  end
  
  if images.length == 0
    puts "no images in #{dir}"
    next
  end
  
  print "Attempting #{dir}... "
  
  # If running in Rails get some ms info
  if defined?(Rails)
    id = dir
    toks = dir.split("-")
    ## if it contains the -xxx just get the ID
    id = toks[0] if toks != [dir]
    if (dir.starts_with?('h'))
      id = dir[1..-1] # strip the H
      begin
        db_element = Holding.find(id)
      rescue ActiveRecord::RecordNotFound
        puts "HOLDING #{id} not found".red
        next
      end
      title = db_element.source.title
    else
      begin
        db_element = Source.find(dir)
      rescue ActiveRecord::RecordNotFound
        puts "SOURCE #{dir} not found".red
        next
      end
      title = db_element.title
    end
    country = "ch" # TODO: Figure out country code from siglum
  end

  # Skip all the manifest generation stuff if we only add the 856
  if options.include?(:onlyadd) && options[:onlyadd] == true
    puts "Manifest creation skipped (-o)"
  else

    if File.exist?(country + "/" + dir + '.json')
      if options.include?(:force) && options[:force] == true
        puts "file exists, overwrite (-f)"
      else
        puts "already exists, skip"
        next
      end
    end

    manifest_id = "#{IIIF_PATH}/manifest/#{country}/#{dir}.json"

    # Create the base manifest file
    related = {
      "@id" => "https://www.rism-ch.org/catalog/#{dir}",
      "format" => "text/html",
      "label" => "RISM Catalogue Record"
    }
    seed = {
        '@id' => manifest_id,
        'label' => title,
        'related' => related
    }
    # Any options you add are added to the object
    manifest = IIIF::Presentation::Manifest.new(seed)
    sequence = IIIF::Presentation::Sequence.new
    manifest.sequences << sequence
    
    images.each_with_index do |image_name, idx|
      canvas = IIIF::Presentation::Canvas.new()
      canvas['@id'] = "#{IIIF_PATH}/canvas/#{country}/#{dir}/#{image_name.chomp(".tif")}"
      canvas.label = "[Image #{idx + 1}]"
      
      image_url = "#{IIIF_PATH}/image/#{country}/#{dir}/#{image_name}"
      
      image = IIIF::Presentation::Annotation.new
      image["on"] = canvas['@id']
      image["@id"] = "#{IIIF_PATH}/annotation/#{country}/#{dir}/#{image_name.chomp(".tif")}"
  #puts image_url
      begin
        image_resource = IIIF::Presentation::ImageResource.create_image_api_image_resource(service_id: image_url, resource_id:"#{image_url}/full/full/0/default.jpg")
      rescue
        puts "Not found #{image_url}"
        next
      end

      print "."
      image.resource = image_resource
      
      canvas.width = image.resource['width']
      canvas.height = image.resource['height']
      
      canvas.images << image
      sequence.canvases << canvas
      
      # Some obnoxious servers block you after some requests
      # may also be a server/firewall combination
      # comment this if you are positive your server works
      #sleep 0.1
    end
    
    #puts manifest.to_json(pretty: true)
    File.write(country + "/" + dir + '.json', manifest.to_json(pretty: true))
    puts "Wrote #{country}/#{dir}.json"
    
    if options.include?(:nocreate) && options[:nocreate] == false ## it sets to FLASE when set
      puts "Do not update 856"
      next
    end
  end

  # db_element can be a Source or a Holding, only in Muscat records
  if db_element

    type = db_element.is_a?(Source) ? "source" : "holding"
    marc = db_element.marc
    marc.load_source true

    # The source can contain more than one 856
    # as some sources have more image groups
    # -01 -02 etc
    new_tag = MarcNode.new(type, "856", "", "##")
    new_tag.add_at(MarcNode.new(type, "x", options[:type], nil), 0)
    new_tag.add_at(MarcNode.new(type, "z", options[:banner], nil), 0)
    new_tag.add_at(MarcNode.new(type, "u", manifest_id, nil), 0)

    pi = marc.get_insert_position("856")
    marc.root.children.insert(pi, new_tag)
  
    db_element.suppress_reindex if options.include?(:noreindex) && options[:noreindex] == false

    db_element.save!
  end

end
