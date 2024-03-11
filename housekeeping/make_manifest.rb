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

@tag_cache = {}

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

def get_manifest_tag(marc, tag, subtag, manifest_id)
  marc.each_by_tag(tag) do |t|
    t.fetch_all_by_tag(subtag).each do |tn|

      next if !(tn && tn.content)
      if tn.content == manifest_id
        return t
      end

    end
  end
  nil
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

  opts.on("-p", "--path [PATH]", "Set IIIF server URL path") do |b|
    options[:path] = b
  end

  opts.on("-r", "--no-reindex", "Do not reindex the sources") do |b|
    options[:noreindex] = b
  end

  opts.on("-o", "--only-add", "Do not create the manifests, only add the 856") do |b|
    options[:onlyadd] = b
  end

  opts.on("-m", "--match-metadata [FILE]", "Pull the metadata from a CSV file, ID,BANNER,TYPE") do |b|
    options[:csv] = b
  end

  opts.on("-n", "--normal", "Create generic non-muscat manifests") do |b|
    options[:nomuscat] = b
  end

  opts.on("-c", "--country [CODE]", "Country/dir code") do |b|
    options[:country] = b
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

options[:type] = "IIIF manifest (digitized source)" if !options.include?(:type)
options[:banner] = "Digital Object" if !options.include?(:banner)
options[:country] = "ch" if !options.include?(:country)
options[:nomuscat] = false if !options.include?(:nomuscat)
IIIF_PATH = options[:path] if options.include?(:path)

if options.include?(:csv)
  if !File.exist?(options[:csv])
    puts "The csv file does not exist: #{options[:csv]}"
    exit 1
  end

  CSV::foreach(options[:csv]) do |l|
    @tag_cache[l[0].to_s.strip] = {banner: l[1].strip, type: l[2].strip}
  end
end

if ARGV.first.include?("yml")
  dirs  = YAML.load_file(ARGV.first)
else
  dirs = ARGV
end

puts "Creating manifests for #{ARGV.first}"
puts "Update 856 in record: #{ !(options.include?(:nocreate) && !options[:nocreate])}"
puts "Default Banner 856$z: #{options[:banner].yellow}"
puts "Default Type 856$x: #{options[:type].yellow}"
puts "URL path: #{IIIF_PATH.yellow}"
puts "Force manifest creation: #{ options.include?(:force) && options[:force] == true}"
puts "Skip manifest creation: #{ options.include?(:onlyadd) && options[:onlyadd] == true}"
puts "Directory/Country: #{options[:country]}"
puts "Skip all Muscat operations: #{options[:nomuscat]}"


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

  #print "Attempting #{dir}... "
  spinner = TTY::Spinner.new("Getting info for #{dir} [:spinner]",)
  
  # If running in Rails get some ms info
  if defined?(Rails) && !options[:nomuscat]
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
  end

  manifest_id = "#{IIIF_PATH}/manifest/#{options[:country]}/#{dir}.json"

  # Skip all the manifest generation stuff if we only add the 856
  if options.include?(:onlyadd) && options[:onlyadd] == true
    puts "Manifest creation skipped (-o)"
  else
    
    spinner.auto_spin

    if File.exist?(options[:country] + "/" + dir + '.json')
      if options.include?(:force) && options[:force] == true
        #puts "file exists, overwrite (-f)"
      else
        puts "already exists, skip"
        next
      end
    end

    # Create the base manifest file
    related = {
      "@id" => "https://rism.online/sources/#{dir}",
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
    sequence['@id'] = "#{IIIF_PATH}/sequence/#{options[:country]}/#{dir}"
    sequence["label"] = "Default"
    manifest.sequences << sequence
    
    images.each_with_index do |image_name, idx|
      canvas = IIIF::Presentation::Canvas.new()
      canvas['@id'] = "#{IIIF_PATH}/canvas/#{options[:country]}/#{dir}/#{image_name.chomp(".tif")}"
      canvas.label = "[Image #{idx + 1}]"
      
      image_url = "#{IIIF_PATH}/image/#{options[:country]}/#{dir}/#{image_name}"
      
      image = IIIF::Presentation::Annotation.new
      image["on"] = canvas['@id']
      image["@id"] = "#{IIIF_PATH}/annotation/#{options[:country]}/#{dir}/#{image_name.chomp(".tif")}"
  #puts image_url
      begin
        image_resource = IIIF::Presentation::ImageResource.create_image_api_image_resource(service_id: image_url, resource_id:"#{image_url}/full/full/0/default.jpg")
      rescue
        puts "Not found #{image_url}"
        next
      end

      service = IIIF::Presentation::Resource.new(
        '@context' => 'http://iiif.io/api/image/2/context.json', 
        'profile' => 'http://iiif.io/api/image/2/level1.json', 
        '@id' => image_url)

        image_resource.service = service

      #print "."
      image.resource = image_resource
      
      canvas.width = image.resource['width']
      canvas.height = image.resource['height']
      
      canvas.images << image
      sequence.canvases << canvas
      
      # Some obnoxious servers block you after some requests
      # may also be a server/firewall combination
      # comment this if you are positive your server works
      #sleep 0.5
    end
    
    #puts manifest.to_json(pretty: true)
    File.write(options[:country] + "/" + dir + '.json', manifest.to_json(pretty: true))
    #puts "Wrote #{options[:country]}/#{dir}.json"
    spinner.stop("Wrote #{options[:country]}/#{dir}.json")
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

    if get_manifest_tag(marc, "856", "u", manifest_id)
      puts "856 EXISTS FOR #{db_element.id} #{manifest_id}".green
      next
    end

    if @tag_cache.keys.include?(dir)
      puts "Cache hit #{@tag_cache[dir][:type]} #{@tag_cache[dir][:banner]}"
      type = @tag_cache[dir][:type]
      banner = @tag_cache[dir][:banner]
    else
      type = options[:type]
      banner = options[:banner]
    end

    # The source can contain more than one 856
    # as some sources have more image groups
    # -01 -02 etc
    new_tag = MarcNode.new(type, "856", "", "##")
    new_tag.add_at(MarcNode.new(type, "x", type, nil), 0)
    new_tag.add_at(MarcNode.new(type, "z", banner, nil), 0)
    new_tag.add_at(MarcNode.new(type, "u", manifest_id, nil), 0)

    pi = marc.get_insert_position("856")
    marc.root.children.insert(pi, new_tag)
  
    db_element.suppress_reindex if options.include?(:noreindex) && options[:noreindex] == false

    db_element.save!
  end

end
