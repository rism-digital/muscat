require "awesome_print"

FILENAME="TIT.ASC"

def parse_records(filename)
    records = {}
    current_record = nil
    current_id = nil
  
    File.open(filename, "r:ISO-8859-1") do |file|
      file.each_line do |line|
        line = line.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').chomp
  
        if line.start_with?('###')
            current_record = {}
          current_id = line[3..-1].to_i
          records[current_id] = current_record unless current_id.nil?
        elsif current_record && !line.empty?
          if line =~ /^(\d{3})(.*)/
            tag = $1
            value = $2.strip
  
            current_record[tag] ||= []
            current_record[tag] << value
          end
        end
      end
    end
  
    records
  end
    
  records = parse_records(FILENAME)
    
  File.open("bad-518.txt") do |file|
    file.each_line do |line|
        record = records[line.strip.to_i]
        if !record
            puts "#{line.strip.to_i}\tNot found"
            next
        end

        #ap record

        puts "#{line.strip.to_i}\t#{record['944']}\t#{record['962']}"
    end
  end
