# -*- encoding : utf-8 -*-
#
class CatalogChController < CatalogController
  
  before_action :set_view_path
  
  #def self.controller_path
  #  "catalog_ch" # change path from app/views/catalog_ch to app/views/catalog
  #end
  
  def set_view_path
    prepend_view_path "#{Rails.root}/app/views/#{self.controller_name}"
  end
  
  configure_blacklight do |config|
    config.default_solr_params = { 
      :qt => 'search',
      :"q.alt" => "*:*",
      :rows => 20,
      :defType => 'edismax',
      :fq => "type:Source wf_stage_s:inprogress pae:*",
      :hl => 'false',
      :"hl.simple.pre" => '<span class="highlight">',
      :"hl.simple.post" => "</span>",
      :"facet.mincount" => 1,
    }
  end

end 
