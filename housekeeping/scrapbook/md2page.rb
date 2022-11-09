OUT_DIR = "rism_website/"

pages = YAML.load(File.read("new_articles.yml"))
wl = WhatLanguage.new(:all)

category_map = {
    "new_at_rism": "new_at_rism",
    "library_collections": "library_stocks",
    "new_publications": "new_publications",
    "in_the_news": "press_reviews",
    "events": "events",
    "rediscovered": "rediscovered",
    "electronic_resources": "electronic_resources",
    "rism_a-z": "rism_a_z",
    "rism_online_catalog": "rism_online_catalog",
    "in_memoriam": "in_memoriam",
    "rism_online_catalog,_in_the_news": "press_reviews",
    "rism_online_catalog,_new_at_rism,_new_publications": "new_publications",
    "library_collections,_electronic_resources": "library_stocks",
    "rism_online_catalog,_new_at_rism": "new_at_rism",
    "new_at_rism,_library_collections": "new_at_rism",
}

pages.each do |page|
    [:de, :en, :fr].each do |lang|
        next if !page[0][lang][:body]
        
        next if lang == :fr && wl.language_iso(page[0][lang][:body]) != lang
        
        ## NOTE for consistency the date is always the one from the ENGLISH version
        date = DateTime.parse(page[0][:en][:date])

        directory_date = date.strftime("%Y-%m")
        directory = OUT_DIR + lang.to_s + "/" + directory_date

        system 'mkdir', '-p', directory

        file_date = date.strftime("%Y-%m-%d")
        # File name should be the english one for all articles in each lang
        #post_name = page[0][:en][:title].downcase.gsub(" ", "-").slice(0...25).gsub("/", "")
        post_name = page[0][:en][:title].downcase.gsub("@", "at").gsub(/[^[:word:]\s]/, '').truncate(50, separator: " ", omission: "").gsub(" ", "-")
        file_name = "#{file_date}-#{post_name}.md"
        
        #category = "other"
        #if lang == :en
        # NOTE category is only the english one!
        category = page[0][:en][:category].gsub("Category: ", "").downcase.gsub(" ", "_").strip
        #elsif lang == :de
        #    category =page[0][lang][:category].gsub("Kategorie: ", "").downcase.gsub(" ", "_")
        #else
        #    category = page[0][lang][:category].gsub("Catégorie : ", "").downcase.gsub(" ", "_")
        #end

        email = page[0][lang][:author_email].gsub("mailto:", "") rescue email = "''"
        author = page[0][lang][:author].gsub("Contact: ", "").gsub("Auteur : ", "").gsub("Ansprechpartner: ", "").strip
        author = "''" if author.empty?

        body = page[0][lang][:body].gsub("&nbsp;", "")

        body = body.gsub(" \"Opens external link in new window\")", "){:target=\"_blank\"}")
        body = body.gsub(" \"Öffnet externen Link in neuem Fenster\")", "){:target=\"_blank\"}")
        
        strip_body = body.each_line.map  {|l| l.strip}.join("\n")
    

        File.open(directory + "/" + file_name, "w") do |file|
            file << "---\n"
            file << "layout: post\n"
            file << "title: \"" + page[0][lang][:title].gsub("\"", '\"').strip + "\"\n"
            file << "date: " + file_date + "\n"
            file << "lang: #{lang}\n"
            file << "post: true\n"
            file << "category: " + category_map[category.to_sym] + "\n"
            file << "image: " + page[0][lang][:image_small].gsub("/uploads/_processed_", "/images/news-old-website") + "\n"
            file << "old_url: " + page[0][lang][:url] + "\n"
            file << "email: " + email + "\n"
            file << "author: " + author + "\n"
            file << "---\n"
            file << "\n"

            #file << "{% include image file=\"#{page[0][lang][:image_small]}\" pos=\"left\" %}\n"
            file << "\n"

            file << strip_body
        end
    end

end