START = "/de/startseite/newsdetails/browse/62/article/64/discovery-of-joseph-haydns-original-manuscript-for-the-pieces-hob-xix1-and-hob-xix2-royal-libr.html"
#START =  "/fr/home/newsdetails/browse/62/article/64/discovery-of-joseph-haydns-original-manuscript-for-the-pieces-hob-xix1-and-hob-xix2-royal-libr.html"

#START = "/home/newsdetails/article/64/the-music-for-richard-wagners-rienzi-preserved-in-dresden.html?tx_ttnews%5Byear%5D=2020&tx_ttnews%5Bmonth%5D=07&cHash=9d70bdef93eeb130fccb8bed20f7e3c3"
#START = "en/home/newsdetails/article/64/the-music-for-richard-wagners-rienzi-preserved-in-dresden.html?tx_ttnews[year]=2020&tx_ttnews[month]=07&cHash=9d70bdef93eeb130fccb8bed20f7e3c3"

LINK_TEXT = "Nächster Artikel"
#LINK_TEXT = "Next article"

def get_next_article(url)
    uri = URI(URI::Parser.new.escape(url))
    response = Net::HTTP.get(uri)

    doc = Nokogiri::HTML.parse(response)

    #article = doc.at('a:contains("Article suivant")')
    article = doc.at('a:contains("Nächster Artikel")')
    article['href']
end

=begin
next_article = START
while true do
    puts next_article.gsub("%5B", "[").gsub("%5D", "]")
    next_article = get_next_article("http://141.2.23.17/" + next_article.gsub("%5B", "[").gsub("%5D", "]"))
end

exit 1
=end

def extract_body(article)
    out_html = ""
    elem = article.at('.news-image').next_element

    while true do
        break if elem.attribute("class") && elem.attribute("class").text == "news-single-rightbox"
        out_html << elem.to_html
        elem = elem.next_element
        # Let it crash if there is no news-single-rightbox
    end

    out_html.strip
end

def get_article(url)
    #ap url
    image_big = ""
    image_small = ""
    uri = URI(URI::Parser.new.escape(url))
    response = Net::HTTP.get(uri)

    doc = Nokogiri::HTML.parse(response) do |config|
       # config.strict
    end

    doc.errors.each do |err|
        if err.message.include?("Unexpected end tag")
            puts url
            #ap err
        end
    end

    article = doc.at('.news-single-item')
    return {url: url} if !article

    title = article.search('h1').text
    author = article.at(".news-author").text
    author_email = article.at('a[href^="mailto:"]')['href'] rescue author_email = nil 
    date = article.at('.news-date').text
    image_caption = article.at('.news-image').text
    if article.at('.news-image')
        image_big = article.at('.news-image').at("a")['href'] rescue image_big = nil
        image_small = article.at('.news-image').at("img")['src'] rescue image_small = nil
    end
    body = extract_body(article)
    category = article.at('.news-single-rightbox').text

    title = title.strip if title
    author = author.strip if author
    author_email = author_email.strip if author_email
    date = date.strip if date
    image = image.strip if image
    
    body = ReverseMarkdown.convert(body.strip).strip if body
    category = category.strip if category

    #kd = Kramdown::Document.new(body, :html_to_native => true)
    #puts kd.to_kramdown
    #puts body
    #puts title
    #return title, url

    return {
        title: title,
        author: author,
        author_email: author_email,
        date: date,
        image_caption: image_caption,
        image_big: image_big,
        image_small: image_small,
        body: body,
        category: category,
        url: url
    }

end

def rip_images(url)

    puts url
    image_big = ""
    image_small = ""
    uri = URI(URI::Parser.new.escape(url))
    response = Net::HTTP.get(uri)

    doc = Nokogiri::HTML.parse(response)
    article = doc.at('.news-single-item')
    return {url: url} if !article

    title = article.search('h1').text

    images_and_captions = []

    if article.at('.news-image')
        image_big = article.at('.news-image').at("a")['href'] rescue image_big = nil
        image_small = article.at('.news-image').at("img")['src'] rescue image_small = nil
        images = article.at('.news-image').search("a").map do |image|
            image.at("img")['src']
        end

        captions = article.at('.news-image').search(".news-single-imgcaption").map {|c| c.text}
        images_and_captions = images.zip(captions)
    end

    return images_and_captions

end

#get_article("http://www.rism.info//home/newsdetails/browse/62/article/64/francesco-feo-rism.html")
#rip_images("http://141.2.23.17/en/home/newsdetails/browse/62/article/64/joseph-bolognes-lamant-anonyme.html")
#rip_images("http://141.2.23.17/en/home/newsdetails/browse/3/article/64/music-and-dance-for-the-recovery-of-king-philip-iii-of-spain.html")

#get_article("http://141.2.23.17/en/home/newsdetails/browse/4/select/library-collections/article/2/a-century-of-john-milton-ward.html")
#exit 1

results = {}
reject = []
File.readlines('housekeeping/scrapbook/news_articles').each do |line|
    #data = get_article(line.strip.gsub("home", "startseite"))
    
    #data_en = get_article("http://www.rism.info/en" + line.strip)

    line.gsub!("/en/home", "/de/startseite")
    r = get_article("http://141.2.23.17/" + line.strip)

    results[line] = r

    #data_fr = get_article("http://www.rism.info/fr" + line.strip)
    #data_de = get_article("http://www.rism.info/de" + line.strip.gsub("home", "startseite"))
    #results << [en: data_en, de: data_de, fr: data_fr]

=begin
    [data_en].each do |data|
        if !data.is_a? Hash
            #results[data] = line.strip
            results[line.strip] = data[0].strip
        else
            reject << data[1]
        end
    end
=end
end

File

File.open("all_images_rism.yml", "w") { |file| file.write(results.to_yaml) }
#File.open("new_articles_reject.yml", "w") { |file| file.write(reject.to_yaml) }
