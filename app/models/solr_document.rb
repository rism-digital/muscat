# -*- encoding : utf-8 -*-

require 'blacklight/marcxml.rb'

class SolrDocument

  include Blacklight::Solr::Document

  # self.unique_key = 'id'
  
  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Document::Email )
  
  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Document::DublinCore)
  
  use_extension( Muscat::Blacklight::MarcXML ) 

  #self.unique_key = 'std_title_texts'

  def to_param
    id.to_s.split(" ")[1] #split the "Model XXXXXX"
  end
  
  def source_index_composer
    if first(:composer_texts) == "" || first(:composer_texts) == nil
      "[n.a.]"
    else
      ## :composer_texts is multivalued, one value per line
      ## The first line is always the "official" name
      ## all the alternates are appended. We need just 
      ## the first line for the title.
      first(:composer_texts).split("\n")[0]
    end
  end
  
  def source_index_description
    elements = []
    profile = EditorConfiguration.get_show_layout(Source.new)
    record_type = first(:record_type_is).to_i
    
    if record_type == MarcSource::RECORD_TYPES[:source] || 
       record_type == MarcSource::RECORD_TYPES[:collection]
       
      std_title = first(:"240a_filter_sms")
      std_title = "[n.a.]" if std_title.nil? || std_title.empty?
      std_title += " - "      
      
      if first(:"240r_texts")
        elements << profile.get_label(first(:"240r_texts"))
      end
      
      elements << first(:"240m_filter_sms")
      
      if first(:"690a_texts")
        elements << "#{first(:"690a_texts")} #{first(:"690n_texts")}".strip
      end
      
      elements << first(:"510a_texts")
      elements << first(:"593a_texts")
      
      elements << "#{first(:"852a_texts")} #{first(:"852c_texts")}".strip
      return std_title + elements.compact.join("; ")
      
    elsif record_type == MarcSource::RECORD_TYPES[:edition] || 
          record_type == MarcSource::RECORD_TYPES[:edition_content]
          
      std_title = first(:"240a_filter_sms")
      std_title = "[n.a.]" if std_title.nil? || std_title.empty?
      std_title += " - "      
      
      if first(:"240r_texts")
        elements << profile.get_label(first(:"240r_texts"))
      end
      
      elements << first(:"240m_filter_sms")
      
      if first(:"690a_texts")
        elements << "#{first(:"690a_texts")} #{first(:"690n_texts")}".strip
      end
      
      elements << first(:"593a_texts")
      elements << "#{first(:"510a_texts")} #{first(:"510c_texts")}".strip
      
      return std_title + elements.compact.join("; ")
    else
      return 'title'
    end
  end
  
end
