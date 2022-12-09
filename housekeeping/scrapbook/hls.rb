require 'nokogiri'
require 'net/http'

# unbuffer stdout
STDOUT.sync = true

#to_utf = Iconv.new('UTF-8', 'ISO-8859-1')
#from_utf = Iconv.new('ISO-8859-1', 'UTF-8')

pl = Person.all
count = 0

pl.each do |person|
  #puts "Looking for #{person.full_name}... "
  
  next if person.full_name == " " or person.full_name == "" or person.full_name == nil
  
  #begin
  #  iso_fullname = from_utf.iconv(person.full_name)
  #rescue Iconv::IllegalSequence
    iso_fullname = person.full_name #amen
 # end
  
  post_args = {
    :searchtype => "articles",
    :searchstring => iso_fullname,
    :searchstart => "1",
    :dateletter => "",
    :searchft => "simple",
    :curlg => "d",
    :process => "now",
    :searchlang => "d"
  }


  url = URI("http://www.hls-dhs-dss.ch/index.php")
  resp = Net::HTTP.post_form(url, post_args)
	
	#puts post_args
  #puts resp.body
	
  doc = Nokogiri::HTML.parse(resp.body)
	
  doc.search('a').each do |elm|
		#puts elm
    if elm.content == iso_fullname
      puts "Looking for #{person.full_name}... "
      puts "\tFound #{elm.content}"
      filename = elm['href'].split('/').last
      filename.gsub!(/.php/, "")
      filename.gsub!(/D/, "")
      puts "\tID is: #{filename}"
			
      puts filename, person
    end
  end

  print "[#{count}]" if count % 10 == 0
  count = count + 1
  #sleep(1)
end