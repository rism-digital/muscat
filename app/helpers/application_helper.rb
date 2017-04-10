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
      link_to(value, catalog_path(value))
    else
      link_to( value, { :action => "show", :controller => "admin/sources", :id => value })
    end
  end
  
  # Link a manuscript by its RISM id
  def application_helper_link_to_library(value, subfield, opac)
		if opac
			link_to value, catalog_index_path(:search_field => "library_siglum", :q => value)
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

    if source.record_type == MarcSource::RECORD_TYPES[:source]
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

  #Sanitize date of AA filter
  def self.to_sanitized_date(string)
    return if string.blank?
    if string =~ /[0-9]{4}\-[0-9]{2}\-[0-9]{2}/
      string.to_date
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

end
