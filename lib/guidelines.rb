class Guidelines
  
  attr_accessor :output, :sidebar, :version
  
  def initialize(ymlfile, lang)
    @tag_index = Array.new
    @lang = lang
    @tree = YAML::load(File.read(ymlfile))
    @coder = HTMLEntities.new
    # check if the language exists in the wanted lang
    if (!@tree[:lang].include?(lang))
      @lang = "en"
    end
    s = Source.new
    @profile = EditorConfiguration.get_show_layout( s )
    @output = ""
    @sidebar = Array.new
    @version = @tree[:version]
    
    # numbering
    @chapterNb = 1
    @sectionNb = 1
    @subsectionNb = 1
    
    cat @tree[:header] if @tree[:header]
    @tree[:doc][:chapters].each do |c| 
      chapter c
    end
    
    if @tree[:tag_index] && !@tag_index.empty?
      name = "#{@chapterNb} &ndash; #{@coder.encode(@profile.get_label("doc_tag_index"), :named)}"
      @output +=  "<h1 id=\"tag_index\">#{name}</h1>\n"
      @sidebar << [name,"tag_index",Array.new];
      @output +=  "<table>\n"  
      @tag_index.sort_by { |entry| entry[:id] }.each do |entry|
        @output +=  "<tr><td><a href=\"##{entry[:id]}\">#{entry[:id]} - #{entry[:text]}</a></td></tr>"
      end
      @output +=  "</table>\n"
    end
    
    cat @tree[:footer] if @tree[:footer]
  end
  
  def chapter c
    name = "#{@chapterNb} &ndash; #{@coder.encode(@profile.get_label(c[:title]), :named)}"
    @output +=  "<h1 id=\"#{c[:title]}\">#{name}</h1>\n" if c[:title]
    @sidebar << [name,c[:title],Array.new];
    cat c[:helpfile] if c[:helpfile]
    sections =  c[:sections]
    if sections
      @sectionNb = 1
      sections.each do |s|
        section s if s
      end
    end
    @chapterNb += 1
  end
  
  def section s
    name = "#{@chapterNb}.#{@sectionNb} &ndash; #{@coder.encode(@profile.get_label(s[:title]), :named)}"
    @output +=  "<h2 id=\"#{s[:title]}\">#{name}</h2>\n" if s[:title]
    @sidebar.last[2]   << [name, s[:title]];
    cat  s[:helpfile] if s[:helpfile]
    subsections = s[:subsections]
    if subsections
      @subsectionNb = 1
      subsections.each do |ss|
        subsection ss if ss
      end  
    end 
    
    @sectionNb += 1
  end
  
  def subsection ss
    name = "#{@chapterNb}.#{@sectionNb}.#{@subsectionNb} &ndash; #{@coder.encode(@profile.get_label(ss[:title]), :named)}"
    @output +=  "<h3 id=\"#{ss[:title]}\">#{name}</h3>\n" if ss[:title]
    cat  ss[:helpfile] if ss[:helpfile]
    if ss[:index] 
      @tag_index << { :id => ss[:title], :text => @coder.encode(@profile.get_label(ss[:title]), :named)}
    end
    
    @subsectionNb += 1
  end
  
  def cat helpfile
    text = IO.read("#{Rails.root}/public/help/#{RISM::MARC}/#{helpfile}_#{@lang}.html")
    @output += text
  end
end
