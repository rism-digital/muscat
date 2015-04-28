module Blacklight::Solr::Document
  
  def to_param
    id.to_s.split(" ")[1] #split the "Model XXXXXX"
  end
  
end