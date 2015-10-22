
# example call
# rails r housekeeping/catalogue/generate_doc.rb cat_config.yml ~/cat_output.html cat_folder_id de

require 'htmlentities'


class RISMCatalogue
  
  def initialize(ymlfile, output, folder, lang)
 
    @tag_index = Array.new
    @coder = HTMLEntities.new
    # set the lang
    @lang = lang
    I18n.locale = lang
    # an empty source for loading the configurations
    s = Source.new
    @profile = EditorConfiguration.get_show_layout s
    @marc_configuration = MarcConfigCache.get_configuration "source"
    # load the catalogue config
    @tree = YAML::load(File.read(ymlfile))
    # list of material tag used in the catalogue
    @material_tags_used = Array.new
    @material_tags_used = @tree[:material_tags_used] if @tree[:material_tags_used]
    # open the output file
    @output = File.open( output , "w")  
    
    # header
    @output.write "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n<html>\n<head>\n"
    @output.write "<meta http-equiv=\"content-type\" content=\"text/html; charset=UTF-8\">\n"
    @output.write "<script src=\"#{@tree[:verovio_path]}\" type=\"text/javascript\"></script>\n"
    @output.write "</head>\n<body>"
    @output.write "<script type=\"text/javascript\">\n\
      var vrvToolkit = new verovio.toolkit();\n\
      var options = JSON.stringify({ inputFormat: 'pae', font: 'Leipzig', scale: 50, border: 0, spacingStaff: 5, adjustPageHeight: 1 });\n</script>\n"
      
    # load the folder content and sort it
    @folder = Folder.find_by_id( folder );
    items = Array.new
    @folder.folder_items.each do |i|
    	item = Source.find_by_id(i.item_id)
      # sort field should be made part of the config
    	items << { :item_id => item.id , :sort_field => [item.shelf_mark, item.id] } # change this to change item order in the catalogue
    end
    
    items.sort_by{ |item| item[:sort_field] }.each do |i|
      @item = Source.find_by_id(i[:item_id])
      puts i[:item_id], @item.id
    	@output.write  "<h4>\n" 
      get_tags @tree[:header][:tag], @tree[:header][:subfields], true if @tree[:header][:tag] # always one row with header
      eval @tree[:header][:function]
      # get the template name
      template = EditorConfiguration.get_applicable_layout(@item)
      @output.write " &ndash; #{template.name}"
      @output.write  "</h4>\n" 
    	
    	@output.write  "<table>\n"   	 		
    	@tree[:tags].each do |e|
        get_tags e[:tag], e[:subfields], e[:onerow] if e[:tag]
        eval e[:function] if e[:function]
        get_material e[:material_tags] if e[:material_tags]
        output_separator e[:separator] if e[:separator]
      end
      @output.write  "</table>\n"
    end
    
    @output.write "\t</body>\n</html>\n"
    
    @output.close
    return
    
    @output.close
  end

  
  def get_material material_tags
    # tags without $8
  	#material = MarcConfig.tags_with_subtag("8")
  	#puts @material_tags_used

  	# tags with empty $8 	
  	# do we have material tags without $8 ?
  	tags = @item.marc.by_tags_with_subtag(@material_tags_used, "8", "")
  	if tags.size > 0
    	#@output.write  "MATERIAL<br>\n"
    	# output the material using the order and subfield options
    	output_material material_tags, ""	
  	end
  	
  	# tags with "Material X" $8
  	(1..10).each do |m|
  		tags = @item.marc.by_tags_with_subtag(@material_tags_used, "8", "0#{m}")
  		unless tags.empty?
  		  output_material material_tags, "0#{m}"
      end
    end
  	
  end
  
  def get_tags tag_name, subfields, onerow
    @item.marc.each_by_tag(tag_name) do |tag|
      output_tag tag, subfields, onerow 
    end
  end
  
  def output_tag tag, subfields = nil, onerow = nil
    
    @output.write "<tr><td style=\"vertical-align: top;\">#{@profile.get_label(tag.tag)}</td><td>"
    
    output = 0
    if subfields
      subfields.each do |subfield_name|
        tag.each_by_tag(subfield_name) do |subfield|
          @output.write " &ndash; " if onerow && output > 0
          output_subfield tag, subfield
          output += 1
          #@output.write  " *** #{tag.tag} - #{subfield.tag}<br>\n" if !onerow
          @output.write "<br>\n" if !onerow
        end
      end
    else
      tag.children do |subfield|
        next if @marc_configuration.always_hide?(tag.tag, subfield.tag) || !@marc_configuration.show_in_browse?(tag.tag, subfield.tag)
        @output.write " &ndash; " if onerow && output > 0
        output_subfield tag, subfield
        output += 1
        @output.write "<br>\n" if !onerow
      end
    end 
    @output.write "</td></tr>\n"
  end
  
  def output_subfield tag, subfield
    content = @marc_configuration.is_foreign?(tag.tag, subfield.tag) ? subfield.looked_up_content : subfield.content
    @output.write  "#{@coder.encode(content)}"
  end
  
  def output_material material_tags, set
    @output.write "<tr><td><em>Material #{set}</em></td><td></td></tr>" if !set.empty?
	  material_tags.each do |e|
	    tags = @item.marc.by_tags_with_subtag([e[:tag]], "8", set)
	    tags.each do |tag|
        output_tag tag, e[:subfields], e[:onerow]
      end
    end
  end
  
  def output_separator separator
    @output.write  "<tr><td colspan=\"2\" style=\"padding: 5px 0px; color: #BF3E18;\">#{@profile.get_label(separator)}</td></tr>\n"
  end
  
  # special function
 
  def function_001
    tag_001 = @item.marc.first_occurance("001")
    @output.write "#{tag_001.content}" if tag_001
  end   
  
  def function_031
    @item.marc.each_by_tag("031") do |tag|
      output_tag tag, nil, true
      # image
    	number_a = tag.fetch_first_by_tag('a')
      number_b = tag.fetch_first_by_tag('b')
      number_c = tag.fetch_first_by_tag('c')
      next if !number_a || !number_b || !number_c
    	incipit_number = "#{number_a.content}.#{number_b.content}.#{number_c.content}"
    	pae_subfield = tag.fetch_first_by_tag('p')
    	next if !pae_subfield
      incipit = "#{@item.id}-#{incipit_number}" 
      
    	clef = tag.fetch_first_by_tag('g')
      clef = clef.content if clef
      key_sig = tag.fetch_first_by_tag('n')
      key_sig = key_sig.content if key_sig
      time_sig = tag.fetch_first_by_tag('o')
      time_sig = time_sig.content if time_sig
      
      @output.write  "<tr><td colspan=\"2\">\n"
      @output.write  "<div id=\"#{incipit}\"></div>\n"    
      @output.write  "</td></tr>\n" 
      
      incipit_data = "@clef:#{clef}\\n@keysig:#{key_sig}\\n@timesig:#{time_sig}\\n@data:#{pae_subfield.content}"
      
      @output.write  "<script type=\"text/javascript\">\n\
        document.getElementById(\"#{incipit}\").innerHTML = vrvToolkit.renderData( \"#{incipit_data}\", options );\n</script>"
    end
  end
  
   # to be changed to tables 
  def function_100
    tag_100 = @item.marc.first_occurance("100")
    return if !tag_100
    a_tag = tag_100.fetch_first_by_tag(:a)
    d_tag = tag_100.fetch_first_by_tag(:d)
    content = (a_tag ? a_tag.looked_up_content : "")
    lifedates = (d_tag ? d_tag.looked_up_content : nil)
    @output.write "#{content}"
    @output.write " (#{lifedates})" if lifedates
    @output.write "<br>\n"
  end
  
  # to be changed to tables
  def function_245_246
    @output.write "<em>"
    get_tags "245", nil, nil
    get_tags "246", nil, nil
    @output.write "</em>"
  end 
  
  def function_594
    output = 0
    last_subfield = ""
    @item.marc.each_by_tag("594") do |tag|
      @output.write "<tr><td  style=\"vertical-align: top;\">#{@profile.get_label("594")}</td><td>"
      tag.children do |subfield|
        next if !subfield.content || subfield.content.length == 0
        if subfield.tag == last_subfield
            @output.write ", #{subfield.content}"
        else
          @output.write "<br>\n" if output > 0
          @output.write "#{@profile.get_sub_label("594", subfield.tag)}: #{subfield.content}"
        end
        last_subfield = subfield.tag
        output += 1
      end
      @output.write "</td></tr>\n"
    end
  end
  
  # to be changed to tables
  def function_700_710
    tags = @item.marc.by_tags(["700", "710"])
    tags.each do |tag|
      subfield_4 = tag.fetch_first_by_tag("4")   
      label = @profile.get_label(subfield_4.content) if subfield_4
      @output.write  "#{label}: " if label && label.length > 0
      output_tag tag, ["a", "b"], true
    end
  end
  
  def function_852
    @output.write "<tr><td>#{@profile.get_label("852")}</td><td>"
    tag_852 = @item.marc.first_occurance("852")
    b_tag = tag_852.fetch_first_by_tag(:b)
    p_tag = tag_852.fetch_first_by_tag(:p)
    output_subfield tag_852, b_tag unless !b_tag  
    @output.write " &nbsp; "
    output_subfield tag_852, p_tag unless !p_tag
    @output.write "</td></tr>\n"
  end
  
  def function_collection
    #if @item.std_title_d == '-'
      @output.write "<tr><td>Collection</td><td>#{@item.std_title}</td></tr>\n"
    #end
  end
  
end

# arg 1 is input yml file
# arg 2 output filename 
# arg 3 folder
# arg 4 language
doc = RISMCatalogue.new(ARGV[0], ARGV[1], ARGV[2], ARGV[3])

