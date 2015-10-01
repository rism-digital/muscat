
# example call
# rails runner housekeeping/admin/generate_doc.rb guidelines.yml ./public/help/editor/RISM-CH-guidelines-de.html de

require 'htmlentities'


class RISMDoc
  
  def initialize(ymlfile, output, lang)
    @tag_index = Array.new
    @lang = lang
    @tree = YAML::load(File.read(ymlfile))
    @coder = HTMLEntities.new
    s = Source.new
    @profile = EditorConfiguration.get_show_layout( s )
    @output = File.open( output , "w")  
    
    cat @tree[:header] if @tree[:header]
    @tree[:doc][:chapters].each do |c| 
      chapter c
    end
    
    if @tree[:tag_index] && !@tag_index.empty?
      @output.write  "<h1>#{@coder.encode(@profile.get_label("doc_tag_index"), :named)}</h1>\n"
      @output.write  "<table>\n"  
      @tag_index.sort_by { |entry| entry[:id] }.each do |entry|
        @output.write  "<tr><td><a href=\"#{entry[:id]}\">#{entry[:id]} - #{entry[:text]}</a></td></tr>"
      end
      @output.write  "<table>\n"  
    end
    
    cat @tree[:footer] if @tree[:footer]
    
    @output.close
  end
  
  def chapter c
    @output.write  "<h1 id=\"#{c[:title]}\">#{@coder.encode(@profile.get_label(c[:title]), :named)}</h1>\n" if c[:title]
    cat c[:helpfile] if c[:helpfile]
    sections =  c[:sections]
    if sections
      sections.each do |s|
        section s if s
      end
    end
  end
  
  def section s
    @output.write  "<h2 id=\"#{s[:title]}\">#{@coder.encode(@profile.get_label(s[:title]), :named)}</h2>\n" if s[:title]
    cat  s[:helpfile] if s[:helpfile]
    subsections = s[:subsections]
    if subsections
      subsections.each do |ss|
        subsection ss if ss
      end  
    end 
  end
  
  def subsection ss
    @output.write  "<h3 id=\"#{ss[:title]}\">#{@coder.encode(@profile.get_label(ss[:title]), :named)}</h3>\n" if ss[:title]
    cat  ss[:helpfile] if ss[:helpfile]
    if ss[:index] 
      @tag_index << { :id => ss[:title], :text => @coder.encode(@profile.get_label(ss[:title]), :named)}
    end
    #puts ss.to_yaml
  end
  
  def cat helpfile
    f = File.open("#{Rails.root}/public/help/#{RISM::MARC}/#{helpfile}_#{@lang}.html")
    f.each do |line|
      @output.write line
    end
    f.close
  end
  
end


lang = "en"
# use arg 3 to change language
if ARGV.length >= 3
  I18n.locale = ARGV[2]
  lang = ARGV[2]
end

# arg 1 is input yml file, arg 2 output filename
guidelines = Guidelines.new("#{Rails.root}/public/help/#{RISM::MARC}/#{ARGV[0]}", lang)
outfile = File.open( ARGV[1] , "w") 
outfile.write guidelines.output
outfile.close
