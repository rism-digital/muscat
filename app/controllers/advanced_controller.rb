class AdvancedController < BlacklightAdvancedSearch::AdvancedController
  before_action :save_controller
  
  def save_controller
    @catalog_controller = params.include?(:c) ? params[:c] : ""
  end

  copy_blacklight_config_from(CatalogController)
end