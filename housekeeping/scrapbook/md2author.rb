OUT_DIR = "rism_website/"

pages = YAML.load(File.read("rism_website_md.yml"))
wl = WhatLanguage.new(:all)


pages.each do |page|
    [:de, :en, :fr].each do |lang|
        next if !page[0][lang][:body]
        
        next if lang == :fr && wl.language_iso(page[0][lang][:body]) != lang
        
        ## NOTE for consistency the date is always the one from the ENGLISH version
        date = DateTime.parse(page[0][:en][:date])

        directory_date = date.strftime("%Y-%m")
        directory = OUT_DIR + lang.to_s + "/" + directory_date

        file_date = date.strftime("%Y-%m-%d")

        post_name = page[0][:en][:title].downcase.gsub("@", "at").gsub(/[^[:word:]\s]/, '').truncate(50, separator: " ", omission: "").gsub(" ", "-")
        file_name = "#{file_date}-#{post_name}.md"


        #File.open(directory + "/" + file_name, "r") do |file|
        #    puts file.read
        #end
        
        count = 0
        body = ""
        File.open(directory + "/" + file_name).each_line do |line|
            count += 1 if line =~ /---/

            body << line if count > 1
        end

        header = YAML.load(File.read(directory + "/" + file_name))
        
        email = page[0][lang][:author_email].gsub("mailto:", "") rescue email = ""

        header["old_url"] = page[0][lang][:url]
        header["email"] = email
        header["author"] = page[0][lang][:author].gsub("Contact: ", "").gsub("Auteur : ", "").gsub("Ansprechpartner: ", "").strip

        File.open(directory + "/" + file_name, "w") do |file|
            file << header.to_yaml(line_width: -1)
            #file << "\n---\n"
            file << body
        end


    end

end