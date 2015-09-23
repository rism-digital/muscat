class MarcInstitution < Marc
  def initialize(source = nil)
    super("institution", source)
  end

  def get_name_and_place
    name = ""
    place = ""

    if node = first_occurance("110", "a")
      if node.content
        name = node.content.truncate(128)
      end
    end

    if node = first_occurance("110", "c")
      if node.content
        place = node.content.truncate(24)
      end
    end
    [name, place]
  end
  def get_address_and_url
    address = ""
    url = ""

    if node = first_occurance("622", "e")
      if node.content
        address = node.content.truncate(128)
      end
    end

    if node = first_occurance("622", "u")
      if node.content
        url = node.content.truncate(24)
      end
    end
    [address, url]
  end

  def get_siglum
    if node = first_occurance("110", "g")
      if node.content
        node.content.truncate(32)
      end
    end
  end
end
