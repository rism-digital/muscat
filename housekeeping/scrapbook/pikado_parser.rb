require "awesome_print"

FILENAME="/Users/xhero/Downloads/TIT.ASC"

def parse_records(filename)
  records = {}
  current_record = nil
  current_id = nil
  spinner = TTY::Spinner.new("[:spinner] :title", format: :shark)

  pb = ProgressBar.new(643976)

  File.open(filename, "r:ISO-8859-1") do |file|
    file.each_line do |line|
      line = line.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').chomp

      if line.start_with?('###')
        current_record = {}
        current_id = line[3..-1].to_i
        records[current_id] = current_record unless current_id.nil?
        pb.increment!
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

# Dump all the records to a semblance of marc
File.open("pikado2marc.txt", "w") do |file|

  records.each do |record|
    file.write "\n"
    file.write "=LDR  04289ndmaa2200493uc 4500\n"
    file.write "=001  #{record[0]}\n"
    record[1].each do |tag, values|
      values.each do |value|
        file.write "=#{tag}  \\\\$a#{value}\n"
      end
    end
  end

end


=begin
  # do things
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
=end