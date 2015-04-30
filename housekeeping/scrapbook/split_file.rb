# Split HUGE xml files into chunks
# first argument is the file containing marc records
# second is the model name
# third is the offset to start from

SIZE=50000
#
def change_subfield_code(node, tag, old_code, new_code)
      subfield=node.xpath("//datafield[@tag='#{tag}']/subfield[@code='#{old_code}']")
      subfield.attr('code', new_code) if subfield
      subfield
end

if ARGV.length >= 2
  source_file = ARGV[0]
  model = ARGV[1]
  start = 0
  ofile=File.open("#{Rails.root}/public/#{"%06d" % start}.xml", "w")
  ofile.write("<collection>")
  if File.exists?(source_file)
    import = MarcImport.new(source_file, model, start.to_i)

    import.each_record(source_file) { |record|

      change_subfield_code(record,'773', 'a', 'w')
      change_subfield_code(record,'852', 'x', '0')
      change_subfield_code(record,'852', 'c', 'b')

      ofile.write(record.to_xml :indent => 5, :encoding => 'UTF-8')
      start+=1
      if start % SIZE == 0
        ofile.write("</collection>")
        puts start
        ofile.close
        ofile=File.open("#{Rails.root}/public/#{"%06d" % start}.xml", "w")
        ofile.write("<collection>")
      end
      #break if start==100
    }











    puts "\nCompleted: "+Time.new.strftime("%Y-%m-%d %H:%M:%S")
  else
    puts source_file + " is not a file!"
  end
else
  puts "Bad arguments, specify marc file and model class to use"
end
