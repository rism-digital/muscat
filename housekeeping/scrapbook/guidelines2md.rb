
module ReverseMarkdown
    module Converters
      class Underline < Base
        def convert(node, state = {})
            content = treat_children(node, state.merge(already_crossed_out: true))
            if content.strip.empty? || state[:already_crossed_out]
              content
            else
              "*#{content}*"
            end
          end
      end

      class Comment < Base
        def convert(node, state = {})
            content = treat_children(node, state.merge(already_crossed_out: true))
            if content.strip.empty? || state[:already_crossed_out]
              content
            else
              "#{content}"
            end
          end
      end

      class Font < Base
        def convert(node, state = {})
            content = treat_children(node, state.merge(already_crossed_out: true))
            if content.strip.empty? || state[:already_crossed_out]
              content
            else
              "**#{content}**"
            end
          end
      end

    end
  end

ReverseMarkdown::Converters.register :u, ReverseMarkdown::Converters::Underline.new
ReverseMarkdown::Converters.register :comment, ReverseMarkdown::Converters::Comment.new
ReverseMarkdown::Converters.register :font, ReverseMarkdown::Converters::Font.new

OUTDIR="guidelines_md"

system 'mkdir', '-p', OUTDIR

system 'mkdir', '-p', OUTDIR + "/it"
system 'mkdir', '-p', OUTDIR + "/en"
system 'mkdir', '-p', OUTDIR + "/es"
system 'mkdir', '-p', OUTDIR + "/de"
system 'mkdir', '-p', OUTDIR + "/pt"
system 'mkdir', '-p', OUTDIR + "/pl"
system 'mkdir', '-p', OUTDIR + "/ko"
system 'mkdir', '-p', OUTDIR + "/fr"

files = Dir.glob("public/help/default/*.html")

files.each do |file|
    #puts file
    d = File.read(file)

    if file.include?("authority_en.html")
        data = d.encode('UTF-8', 'UTF-16', :invalid => :replace, :undef => :replace).strip
    else
        data = d
    end

    doc = Nokogiri::HTML.parse(data.strip)

    doc.css('tr').find_all.each do |tr|
        tr.css('p').each { |node| node.replace(node.children) }
        #ap tr
    end

    md = ReverseMarkdown.convert(doc.to_html, unknown_tags: :raise).strip
    md.gsub!("&nbsp;", " ")
 

    name_parts = File.basename(file).gsub(".html", "").split("_")
    lang = name_parts.last
    newname = name_parts[0...-1].join("_") + ".md"

    ap file
    ap lang
    ap newname

    #newname = File.basename(file).gsub("html", "md").downcase
    #puts newname
    File.write("#{OUTDIR}/#{lang}/#{newname}", md)

end
