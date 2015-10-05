# Script for generating guidelines with the lib/guidelines.rb class
# See sample_help.sh for example use

require 'htmlentities'

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
