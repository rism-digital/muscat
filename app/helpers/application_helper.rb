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
  
end
