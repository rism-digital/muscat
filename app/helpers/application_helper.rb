module ApplicationHelper
  
  
  # Create a link for a page in a new window
  def application_helper_link_http(value, node)
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
  def application_helper_link_source_id(value)
    link_to( value, { :action => "show", :controller => "sources", :id => value })
  end
  
  #################
  # These methods are placed here for compatibility with muscat 2
  
  def pe_field_name(tag_name, iterator, subfield, s_iterator)
    it = sprintf("%03d", iterator)
    s_it = sprintf("%04d", s_iterator)
    #"marc[#{tag_name}-#{it}][#{subfield}-#{s_it}]"
    "marc:#{tag_name}-#{it}:#{subfield}:#{s_it}"
  end
  
  def pe_ind_name(tag_name, iterator)
    it = sprintf("%03d", iterator)
    "#{tag_name}-#{it}-indicator"  
  end
  
  # temp. moved here from CW for quick editting
  def action_button(name, icons, link, other_classes = "", place_icon = :left, corner = :all, id = "", is_function = false)
    icon = ""
    classes = ["abutton", "ui-state-default" ]
    classes << other_classes unless other_classes.empty?
    if icons.is_a?(String)
      icon = content_tag(:span, "", {:class => "ui-icon #{icons}"}, false)
    elsif icons.is_a?(Array)
      icon = icons.collect {|i| content_tag(:span, "", {:class => "ui-icon #{i}", :style => "float: left;"}, false) }.join("\n")
    end

    title = ""
    if name && name.is_a?(Array)
      title = name[1]
      name = name[0]
    end

    if name.nil? or name.empty?
      label = icon + "_"
      classes << "abutton-icon-solo"
    elsif place_icon == :right
      label = raw(name + icon)
      classes << "abutton-icon-right"
    else
      label = raw(icon + name)
      classes << "abutton-icon-left"
    end
  
    if corner == :all
      classes << "ui-corner-all"
    elsif corner == :left
      classes << "ui-corner-left"
    elsif corner == :right
      classes << "ui-corner-right"
    end

    if is_function     
      safe_link_to_function_stub(label, link, { :title => title, :id => id, :class => classes.join(' ') })
    else
      link_to(label, link,  { :title => title, :id => id, :class => classes.join(' ') })
    end

  end
  
  # This is a safe version of the deprecated link_to_function, left as a transition
  def safe_link_to_function_stub(name, function, html_options={})
    onclick = "#{"#{html_options[:onclick]}; " if html_options[:onclick]}#{function}; return false;".html_safe
    href = html_options[:href] || '#'

    content_tag(:a, name, html_options.merge(:href => href, :onclick => onclick))
  end
  
  
end
