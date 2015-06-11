module SearchHistoryConstraintsHelper
  include Blacklight::SearchHistoryConstraintsHelperBehavior

  ## OVERRIDDEN to have muscat-like translations
  # Render the name of the facet
  def render_filter_name name
    return "".html_safe if name.blank?
    # Directly use the passed symbol for I18n lookup
    content_tag(:span, "#{t(name)}:", :class => 'filterName')
  end
  
end
