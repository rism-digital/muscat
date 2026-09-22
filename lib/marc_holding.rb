require "uri"

class MarcHolding < Marc
  def initialize(source = nil)
    super("holding", source)
  end
  
  def get_lib_siglum
    title = ""

    if node = first_occurance("852", "a")
      if node.content
        title = node.content.truncate(255)
      end
    end
    title&.strip
  end

  def get_shelf_mark
    m = ""

    if node = first_occurance("852", "c")
      if node.content
        m = node.content
      end
    end
    m.truncate(255)&.strip
  end

  def description
    res = {}
    node = first_occurance("852")
    if node
      node.each do |t|
        if %w(a c q).include?(t.tag)
          res[t.tag] = t.content if t.content
        end
      end
    end
    
    # Sould always be there
    if node && node.foreign_object && node.foreign_object.full_name
      res['name'] = node.foreign_object.full_name.truncate(90) # Avoid overflowing the box
    else
      res['name'] = 'UNNAMED LIBRARY'
    end

    if res.length > 0
      #return "#{res['a']}#{" " + res['c'] if res['c']}#{" [" + res['q'] +"]" if res['q']}"
      res.to_a.join(" ")
      out = "#{res['a']} (#{res['name']})" # library name + siglum
      out += ": #{res['c']}" if res['c'] && res['c'] != "[no indication]" # Do we have a shelfmark?
      out += " [#{res['q']}]" if res['q'] # scoring
      return out&.strip
    else
      I18n.t(:holding_no_siglum)
    end
  end

  def digital_object?
    digital_object_links.any?
  end

  def digital_object_links
    links = []

    each_by_tag("856") do |tag|
      type = tag.fetch_first_by_tag("x")&.content.to_s.strip
      next unless type.start_with?("Digitized")

      url = tag.fetch_first_by_tag("u")&.content.to_s.strip
      next unless valid_digital_object_url?(url)

      description = tag.fetch_first_by_tag("z")&.content.to_s.strip
      links << {
        url: url,
        description: description.empty? ? nil : description
      }
    end

    links
  end

  private

  def valid_digital_object_url?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) && !uri.host.to_s.empty?
  rescue URI::InvalidURIError
    false
  end

end
