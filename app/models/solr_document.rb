# -*- encoding : utf-8 -*-

require 'blacklight/marcxml.rb'
require 'blacklight/marctxt.rb'

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
  use_extension( Muscat::Blacklight::MarcTXT ) 

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
    title = first(:std_title_texts) || "[n.a.]"
    title = "[n.a.]" if title.nil? || title.empty?
    #sigla = first(:lib_siglum_texts) || ""
    #shelf = first(:shelf_mark_texts) || ""
    #desc = first(:"240m_texts") || ""
    #"#{title}; #{desc}; #{sigla} #{shelf}"
    title
  end
  
end
