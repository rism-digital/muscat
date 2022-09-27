def get_article(url)
    ap url
    image_big = ""
    image_small = ""
    uri = URI(URI::Parser.new.escape(url))
    response = Net::HTTP.get(uri)

    doc = Nokogiri::HTML.parse(response)
    article = doc.at('.content-main')

    title = doc.at('.csc-firstHeader').text rescue text = "no title"

    #links = doc.at(".csc-sitemap-level1")
    #puts links.to_html

    #ap article.to_html
    md = ReverseMarkdown.convert(article.to_html.strip).strip
    return md, title
end

pages = [
"/en/publications/music-documentation-2012/program/abstracts.html",
"/en/publications/music-documentation-2012/program.html",
"/en/publications/introducing-a-work-level-in-rism-2019/abstracts.html"
=begin
"/en/publications.html",
"/en/publications/brochures.html",
"/en/publications/bibliography.html",
"/en/publications/conferences.html",
"/en/publications/work-level-2019.html",
"/en/publications/latin-america-conference-2016.html",
"/en/publications/colloquium-2015.html",
"/en/publications/conference-2012.html",
"/en/publications/iaml-conferences.html",
"/en/publications/iaml-congresses/2019.html",
"/en/publications/iaml-congresses/2018.html",
"/en/publications/iaml-congresses/2017.html",
"/en/publications/iaml-congresses/2016.html",
"/en/publications/iaml-congresses/2015.html",
"/en/publications/iaml-congresses/2014.html",
"/en/publications/iaml-congresses/2013.html",
"/en/publications/iaml-congresses/2012.html",
"/en/publications/iaml-congresses/2011.html",
"/en/publications/iaml-congresses/2010.html",
"/en/publications/annual-reports.html",
"/en/publications/annual-reports/2019.html",
"/en/publications/annual-reports/2018.html",
"/en/publications/annual-reports/2017.html",
"/en/publications/annual-reports/2016.html",
"/en/publications/annual-reports/2015.html",
"/en/publications/annual-reports/2014.html",
"/en/publications/annual-reports/2013.html",
"/en/publications/annual-reports/2012.html",
"/en/publications/annual-reports/2011.html",
"/en/publications/annual-reports/2010.html",
"/en/publications/cd-rom-publications-1995-2011.html",
"/en/publications/info-rism.html",
=end
]


pages_de = [
"/de/publikationen/konferenz-2012/conference-2012.html",
"/de/publikationen/konferenz-2012/conference-2012/abstracts.html",
"/de/publikationen/werkebene-2019/abstracts.html"
=begin
"/de/publikationen.html",
"/de/publikationen/broschueren.html",
"/de/publikationen/bibliographie.html",
"/de/publikationen/conferences.html",
"/de/publikationen/werkebene-2019.html",
"/de/publikationen/latin-america-conference-2016.html",
"/de/publikationen/colloquium-2015.html",
"/de/publikationen/konferenz-2012.html",
"/de/publikationen/iaml-conferences.html",
"/de/publikationen/iaml-konferenzen/2019.html",
"/de/publikationen/iaml-konferenzen/2018.html",
"/de/publikationen/iaml-conferences/2017.html",
"/de/publikationen/iaml-conferences/2016.html",
"/de/publikationen/iaml-conferences/2015.html",
"/de/publikationen/iaml-conferences/2014.html",
"/de/publikationen/iaml-conferences/2013.html",
"/de/publikationen/iaml-conferences/2012.html",
"/de/publikationen/iaml-conferences/2011.html",
"/de/publikationen/iaml-conferences/2010.html",
"/de/publikationen/jahresberichte.html",
"/de/publikationen/jahresberichte/2019.html",
"/de/publikationen/jahresberichte/2018.html",
"/de/publikationen/jahresberichte/2017.html",
"/de/publikationen/jahresberichte/2016.html",
"/de/publikationen/jahresberichte/2015.html",
"/de/publikationen/jahresberichte/2014.html",
"/de/publikationen/jahresberichte/2013.html",
"/de/publikationen/jahresberichte/2012.html",
"/de/publikationen/jahresberichte/2011.html",
"/de/publikationen/jahresberichte/2010.html",
"/de/publikationen/cd-rom-publikationen-1995-2011.html",
"/de/publikationen/info-rism-1989-2001.html",
=end
]

system 'mkdir', '-p', 'rism_pages'

lang = "en"
count = 0
pages.each do |pn|

    dir = File.dirname(pn)
    system 'mkdir', '-p', 'rism_pages' + dir

    file_name = File.basename(pn).gsub(".html", ".#{lang}.md")
    if lang == "de"
        file_name = File.basename(pages[count]).gsub(".html", ".#{lang}.md")
    end
    #puts file_name

    md, title = get_article("http://www.rism.info" + pn)


    File.open('rism_pages' + dir + "/" + file_name, "w") do |file|

        file << "---\n"
        file << "layout: publications\n"
        file << "title: \"" + title.strip + "\"\n"
        file << "lang: #{lang}\n"
        file << "permalink: " + pn.gsub("/en", "") + "\n"
        file << "---\n"
        file << "\n"

        md = md.gsub("&nbsp;", "")

        md = md.gsub(" \"Opens external link in new window\")", "){:target=\"_blank\"}")
        md = md.gsub(" \"Öffnet externen Link in neuem Fenster\")", "){:target=\"_blank\"}")

        file << md
    end
    count += 1
end