# -*- encoding : utf-8 -*-
#
module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior

  def application_name
    "Répertoire International des Sources Musicales"
  end
  
  def render_page_title
    ((content_for(:page_title) if content_for?(:page_title)) || @page_title || application_name).sub! application_name, 'The Canons Database'
  end

  def muscat_translate fields
    fields.each do |f|
      f[0] = muscat_translate_if_symbol f[0]
    end
    fields
  end
  
  def muscat_translate_if_symbol field
    field = I18n.t(field) if field.is_a? Symbol
    field
  end
  
  # Overriden from BL app/helpers/blacklight/render_constraints_helper_behavior.rb for handling translations
  def render_constraint_element(label, value, options = {})
    render(:partial => "catalog/constraints_element", :locals => {:label => muscat_translate_if_symbol(label), :value => value, :options => options})    
  end
  
end