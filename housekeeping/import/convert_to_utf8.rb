#!/usr/bin/ruby

require 'iconv'

if ARGV.length == 2
  source_file = ARGV[0]
  if File.exists?(source_file)
    conv = Iconv.new('utf-8', 'windows-1252').iconv(open(ARGV[0]).read)
    out = open(ARGV[1], "wb")
    out.write(conv)
    out.close
  else
    puts source_file + " is not a file!"
  end
else
  puts "Bad arguments, specify marc file to convert and destination file"
end

