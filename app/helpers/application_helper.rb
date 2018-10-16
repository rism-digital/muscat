module ApplicationHelper
  
  def catalogue_default_autocomplete
    autocomplete_catalogue_name_admin_catalogues_path
  end
  
  def institution_default_autocomplete
    autocomplete_institution_name_admin_institutions_path
  end
  
  def library_default_autocomplete
    autocomplete_institution_siglum_admin_institutions_path
  end
  
  def liturgical_feast_default_autocomplete
    autocomplete_liturgical_feast_name_admin_liturgical_feasts_path
  end
  
  def person_default_autocomplete
    autocomplete_person_full_name_admin_people_path
  end
  
  def place_default_autocomplete
    autocomplete_place_name_admin_places_path
  end
  
  def source_default_autocomplete
    autocomplete_source_id_admin_sources_path
  end
  
  def standard_term_default_autocomplete
    autocomplete_standard_term_term_admin_standard_terms_path
  end
  
  def standard_title_default_autocomplete
    autocomplete_standard_title_title_admin_standard_titles_path
  end
  
  def source_solr_default_autocomplete
    autocomplete_source_740_autocomplete_sms_admin_sources_path
  end
  
  def source_594b_solr_default_autocomplete
    autocomplete_source_594b_sms_admin_sources_path
  end
	
  def work_default_autocomplete
    autocomplete_work_title_admin_works_path
  end
  
  # Create a link for a page in a new window
  def application_helper_link_http(value, node, opac)
    result = []
    links = value.split("\n")
    links.each do |link|
      if link.match /(.*)(http:\/\/)([^\s]*)(.*)/
        result << "#{$1}<a href=\"#{$2}#{$3}\" target=\"_blank\">#{$3}</a>#{$4}"
      else
        result << link
      end
    end
    result.join("<br>")
  end
  
  # Link a manuscript by its RISM id
  def application_helper_link_source_id(value, subfield, opac) # This could have never worked
    if opac
      link_to(value, solr_document_path(value))
    else
      link_to( value, { :action => "show", :controller => "admin/sources", :id => value })
    end
  end
  
  # Link a manuscript by its RISM id
  def application_helper_link_to_library(value, subfield, opac)
		if opac
			link_to value, search_catalog_path(:search_field => "library_siglum", :q => value)
		else
			value
		end
  end
  
  #################
  # These methods are placed here for compatibility with muscat 2
    
  def marc_editor_ind_name(tag_name, iterator)
    it = sprintf("%03d", iterator)
    "#{tag_name}-#{it}-indicator"  
  end
    
  # This is a safe version of the deprecated link_to_function, left as a transition
  def safe_link_to_function_stub(name, function, html_options={})
    onclick = "#{"#{html_options[:onclick]}; " if html_options[:onclick]}#{function}; return false;".html_safe
    href = html_options[:href] || '#'

    content_tag(:a, name, html_options.merge(:href => href, :onclick => onclick))
  end
  
  def edit_user_registration_path
  end
  
  def get_allowed_record_type(source)
    return nil if !source.is_a? Source

    if source.record_type == MarcSource::RECORD_TYPES[:source] || source.record_type == MarcSource::RECORD_TYPES[:collection]
      MarcSource::RECORD_TYPES[:collection]
    elsif source.record_type == MarcSource::RECORD_TYPES[:edition_content]
      MarcSource::RECORD_TYPES[:edition]
    else
      nil
    end
  end
	
  def get_allowed_record_type_775(source)
    return nil if !source.is_a? Source
    MarcSource::RECORD_TYPES[:edition]
  end
	
  def get_allowed_record_type_holding(holding)
    return nil if !holding.is_a? Holding
    MarcSource::RECORD_TYPES[:collection]
  end
	
  def get_allowed_lib_siglum_holding(holding)
    return nil if !holding.is_a? Holding
    return holding.lib_siglum
  end

  #Sanitize date of AA filter
  def self.to_sanitized_date(string)
    return if string.blank?
    if string =~ /[0-9]{4}\-[0-9]{2}\-[0-9]{2}/
      #string.to_date
      d = DateTime.parse(string) rescue d = DateTime.now
      return d
    elsif string.size == 4
      return DateTime.strptime(string, "%Y")
    else
      return DateTime.now
    end
  end

  # Calculate the month distance between two dates for the statistics
  def self.month_distance(from_date, to_date)
    raise ArgumentError, "from date > to_date" if from_date > to_date
    target = (to_date.year * 12 + to_date.month) - (Time.now.localtime.year * 12 + Time.now.localtime.month)
    start =  target + (from_date.year * 12 + from_date.month) - (to_date.year * 12 + to_date.month)
    (start..target)
  end

  def make_iiif_anchor(link)
    return link.gsub("http://", "").gsub("/", "").gsub(":", "").gsub(".", "")
  end
  
  ## Parses an arbitrary string and extracts 4- or 8- digit
  # dates, such as 1600 or 18000110 (YYYYDDMM)
  # Bound checking is set to > 1000 and < current year
  # Dates out of bounds are discarded
  # Bound checking can be disabled by callind the funcion
  # with bounds = false (handy for validation)
  # In case of mixed dates it parses the lenght
  # of the first one found
  def date_to_array(line, bounds = true)
    arr = []
    len = 0

    len = 4 if line.match(/(\d{4})/)
    len = 8 if line.match(/(\d{8})/)

    return [] if len == 0

    a = line.scan(/(\d{#{len}})/)
    return [] if !a

    flat = a.sort.uniq
    flat.each do |i|
      if len == 8
        next if (i[0][0..3].to_i < 1000 || i[0][0..3].to_i > Date.today.year) && bounds
        arr << i[0][0..3]
      else
        next if (i[0].to_i < 1000 || i[0].to_i > Date.today.year) && bounds
        arr << i[0]
      end
    end

    arr
  end

  def get_cookie_link
    RISM::COOKIE_PRIVACY_I18N ? "#{RISM::COOKIE_PRIVACY_LINK}#{I18n.locale}".html_safe : RISM::COOKIE_PRIVACY_LINK.html_safe
  end

end
