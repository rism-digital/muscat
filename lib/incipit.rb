require 'timeout'
require 'fileutils'

# Create and fetch incipit images for each example in a Source.
# It used instead of the old Incipit class as this class uses external programs
# to interpret PAE and for image generation.
# This class just runs all the steps to generate the images in <tt>/public/incipits</tt>
# It can use two backends: Verovio or thru abc2ps. Output formats supported are PNG,
# MEI (Verovio only) or SVG (Verovio only)
# The data for the PAE incipit comes from the 031 $p Marc tag, the class is initialized sing
# a MarcNode that provides the tag.<p>
# The programs required are:
# [Verovio] Verovio and rsvg
# [pae2kern] pae2kern, hum2abc (from humextra), abcm2ps and eps2png
# The path of these programs is configure in <tt>config/environment.rb</tt><p>
# The spelling of generate_png, generate_svg and generate_mei is not casual, as these
# functions are called dinamically and the name is generated_ + filetype. For example, 
# a generator for midi should be called generate_midi, so it will be invoked as
# generate([:midi, :png]) from the Source model.

class IncipitCH
  attr_accessor :results
  
  # Initialize the class. mixed is a MarcNode 031, id is the RISM id for the Source
  # The output images end up in <tt>/public/incipits/[00...99]/</tt> divided in base of
  # their last two digits. This is, because incipits are many thousands, not to
  # fill up a single directory with too many files.
  # The output file name is in the form ms_id-$a-$b-$c. The separator is different in UK and CH:<p>
  # 1-2-3 on rism uk<p>
  # 1.2.3 on risk ch<p>
  # This is for historical reasons when UK was updated to the new webapp.
  def initialize(mixed, id)
    @code = "pe"
    # load data
    if mixed.is_a? MarcNode
      # TODO, load data when the marc_node is passed as parameter
      # output directory will certainly have to be changed
      @tmp_path = "#{Rails.root}/tmp/incipits/input/"
      # home dir
      @out_path = "#{Rails.root}/public/incipits/#{id[12,14]}/"


      if RISM::BASE == "uk" then
        @number = mixed.fetch_first_by_tag('a').content || "na"
        @number = @number + "-" + mixed.fetch_first_by_tag('b').content || "nb" rescue @number + "-" + "nb"
        @number = @number + "-" + mixed.fetch_first_by_tag('c').content || "nc" rescue @number + "-" + "nc"
      else
        @number = mixed.fetch_first_by_tag('a').content || "no-number"
        @number = @number + "." + mixed.fetch_first_by_tag('b').content || "?" rescue @number + "." + "?"
        @number = @number + "." + mixed.fetch_first_by_tag('c').content || "?" rescue @number + "." + "?"
      end
      
      @clef = mixed.fetch_first_by_tag('g').content || 'none' rescue @clef = 'none'
      @keysig = mixed.fetch_first_by_tag('n').content || 'none' rescue @keysig = 'none'
      @timesig = mixed.fetch_first_by_tag('o').content || 'none' rescue @timesig = 'none'
      @incipit = mixed.fetch_first_by_tag('p').content || 'none' rescue @incipit = 'none'
      @keymode = mixed.fetch_first_by_tag('r').content || ' ' rescue @keymode = ' ' ## 80390 out of 113435
      @file_name = id.to_s + "-" + @number
    elsif mixed.is_a? WorkIncipit
      @tmp_path = "#{Rails.root}/tmp/incipits/input/"
      id_string = "0" + mixed.id.to_s
      @out_path = "#{Rails.root}/public/incipits/#{id_string[0,2]}/"
      #@number = mixed.movement || "no-number"
      #@number = @number + "." + mixed.excerpt || "none" rescue @number + "." + "none"
      #@number = @number + "." + mixed.heading || "none" rescue @number + "." + "none"
      @clef = mixed.clef || 'G-2' rescue @clef = 'G-2'
      @keysig = mixed.key_signature || '' rescue @keysig = ''
      @timesig = mixed.time_signature || '' rescue @timesig = ''
      @incipit = mixed.notation || '' rescue @incipit = ''
      # cleanup output directory
      @file_name = id_string #+ "-" + @number
      if mixed.code == "da"
        @code = "darms"
      end
    else
      @tmp_path = "#{Rails.root}/tmp/incipits/input/"
      @out_path = "#{Rails.root}/public/incipits/input/"
      @file_name = rand.to_s
      @clef = mixed[:clef] || 'G-2' rescue @clef = 'G-2'
      @keysig = mixed[:keysig] || '' rescue @keysig = ''
      @timesig = mixed[:timesig] || '' rescue @timesig = ''
      @incipit = mixed[:incipit] || '' rescue @incipit = ''
      # cleanup output directory
      FileUtils.rm Dir.glob("#{@out_path}*") 
    end
    @results = ""
  end
  
  # Writer a properly formatted PAE file starting from the data gathered from tag 013
  # that can be fed to pae2kern or Verovio. @tmp_path is the folder where to write the 
  # file. It is set in initialize to <tt>Rails.root + "/tmp/incipits/input/</tt>
  def write_pae_input
  	output = File.new("#{@tmp_path}#{@file_name}.pae", "w")
  	output.write "@start:#{@file_name}\n"
    output.write "@clef:#{@clef}\n"
    output.write "@keysig:#{@keysig}\n"
    output.write "@key:#{@keymode}\n"
    output.write "@timesig:#{@timesig}\n"
    output.write "@data:#{@incipit}\n"
    output.write "@end:#{@file_name}\n"
    output.close 
  end
  
  def write_darms_input
  	output = File.new("#{@tmp_path}#{@file_name}.darms", "w")
    output.write "#{@incipit}\n"
    output.close 
  end
  
  # Generate a png image in the output forlder. <p>
  # If the selected backend is Aruspx (RISM::USE_VEROVIO == true), it will invoke this program to generate
  # an SVG and then call RSVG to convert it to PNG.<p>
  # If the selected backend is abcm2ps, the workflow is pae2kern -> hum2abc -> abcm2ps -> eps2png. The configuration
  # file for abcm is in <tt>/config/abcm2ps.fmt</tt>.
  # The return value is "" in case of error or "[OK]" + file name in case of success.

  def generate_png
    abcm2ps_file = "#{Rails.root}/config/abcm2ps.fmt"
    #puts abcm2ps_file
    # 
    write_pae_input
    # go through the conversion steps
    if RISM::USE_VEROVIO == true
      if @code == "darms"
        write_darms_input
        # Works only with Verovio + rsvg
        return "" if !_do "#{VEROVIO} --adjust-page-height --page-width=1570 -s 40 -f darms -r #{VEROVIO_DATA} -o #{@tmp_path}#{@file_name}.svg #{@tmp_path}#{@file_name}.darms", 10
  	    return "" if !_do "#{RSVG} #{@tmp_path}#{@file_name}.svg #{@out_path}#{@file_name}.png", 20
      else
      	return "" if !_do "#{VEROVIO} --adjust-page-height --page-width=1570 -s 40 -f pae -r #{VEROVIO_DATA} -o #{@tmp_path}#{@file_name}.svg #{@tmp_path}#{@file_name}.pae", 10
      	return "" if !_do "#{RSVG} #{@tmp_path}#{@file_name}.svg #{@out_path}#{@file_name}.png", 20
      end
    else
    	return "" if !_do "#{PAE2KERN} -a '-n -1 -Q \"\" --spacing 2.0' -d #{@tmp_path} #{@tmp_path}#{@file_name}.pae", 2
    	return "" if !_do "#{HUM2ABC} -M none -T \" \" #{@tmp_path}#{@file_name}.krn > #{@tmp_path}#{@file_name}.abc", 2
    	return "" if !_do "#{ABCM2PS} -F #{abcm2ps_file} -E -O #{@tmp_path}#{@file_name}.eps #{@tmp_path}#{@file_name}.abc", 2
    	return "" if !_do "#{EPS2PNG} --antialias 4 --scale 1.25 --output #{@out_path}#{@file_name}.png #{@tmp_path}#{@file_name}001.eps", 2 
    	# catalog 
    	#return "" if !_do "#{EPS2PNG} --antialias 4 --resolution 300 --scale 0.65 --output #{@out_path}#{@file_name}.png #{@tmp_path}#{@file_name}001.eps", 2  
    	#return "" if !_do "#{EPS2PDF} --outfile=#{@out_path}#{@file_name}.pdf #{@tmp_path}#{@file_name}001.eps", 2  
    end
    
    # remove temporary files
    begin
      FileUtils.rm "#{@tmp_path}#{@file_name}.svg"
      FileUtils.rm "#{@tmp_path}#{@file_name}.pae"
    rescue
      @results += "Cannot unlink temp files"
    end
    
    @results += "[ OK ] #{@file_name}.png"
    @file_name
  end
  
  # Generates the svg file directly with Verovio
  def generate_svg
    write_pae_input
    # go through the conversion steps
    return "" if !_do "#{VEROVIO} --adjust-page-height -s 50 -f pae -r #{VEROVIO_DATA} -o #{@out_path}#{@file_name}.svg #{@tmp_path}#{@file_name}.pae", 2
    # catalog 
    @results += "[ OK ] #{@file_name}.svg"
    @file_name
  end
  
  # Generates a mei file with Verovio
  def generate_mei
    write_pae_input
    # go through the conversion steps
    return "" if !_do "#{VEROVIO} -t mei -f pae -r #{VEROVIO_DATA} -o #{@out_path}#{@file_name}.mei #{@tmp_path}#{@file_name}.pae", 2
    # catalog 
    @results += "[ OK ] #{@file_name}.mei"
    @file_name
  end
  
  # Uses pae2kern to write a humdrum file
  def generate_humdrum
    # cleanup output directory
    # FileUtils.rm Dir.glob("#{@out_path}*")  
    # 
    write_pae_input
    # go through the conversion steps
    return "" if !_do "#{PAE2KERN} -a '-n -1 -Q \"\" --spacing 2.0' -d #{@out_path} #{@tmp_path}#{@file_name}.pae", 2
    # remove temporary files
    #FileUtils.rm Dir.glob("#{@tmp_path}*")
    @file_name
  end
  
  # private function to execute a system command.
  def _do cmd_val, timeout_val
    process = IO.popen(cmd_val)
    begin
        timeout(timeout_val) {
            Process.wait process.pid
        }
    rescue Timeout::Error 
        #puts "PID ********** * #{process.pid}"
        # Very strange, process.pid seems to be the wrong pid.... +1 fix it!
        Process.kill 'TERM', (process.pid + 1) rescue process.close
        process.close
        @results = "[ FAILED ] TIMEOUT for #{cmd_val}"
        return false
    end
    process.close
    if $? != 0
      @results = "[ FAILED ] #{cmd_val}"
      return false
    end
    return true
  end   
    
end
