# frozen_string_literal: true
class SearchHistoryController < ApplicationController
  include Blacklight::SearchHistory

  helper BlacklightAdvancedSearch::RenderConstraintsOverride
  helper BlacklightRangeLimit::ViewHelperOverride
  helper RangeLimitHelper
	
  def index
    @catalog_controller = params.include?(:catalog_controller) ? params[:catalog_controller] : "catalog"
    if session[:history].blank?
      @searches = ::Search.none
    else
      @searches =  ::Search.where(id: session[:history]).order("updated_at desc").to_a
      @searches.delete_if {|s| s.query_params[:controller] != @catalog_controller}
    end
  end

  def clear
    catalog_controller = params.include?(:catalog_controller) ? params[:catalog_controller] : "catalog"
    
    if !session[:history].blank?
      searches = ::Search.where(id: session[:history]).order("updated_at desc")
      
      # Just remove the items in the session for this controller
      ids = searches.each.map {|s| s.id if s.query_params[:controller] == catalog_controller}
      session[:history] -= ids.compact
      
      flash[:notice] = I18n.t('blacklight.search_history.clear.success')
    end
        
    redirect_back fallback_location: blacklight.search_history_path
  end

end