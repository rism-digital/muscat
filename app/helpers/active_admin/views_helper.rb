# include the override for group_values
require 'sunspot_extensions.rb'

module ActiveAdmin::ViewsHelper
  
  # embedds a list of sources from a foreign (authority) model
  # - context is the show context is the AA
  # - item is the instance of the model
  # - query is the fitler for the source list
  # - src_list_page is the pagination
  def active_admin_embedded_source_list( context, item, query, src_list_page )
    # get the list of sources for the item
    c = item.sources
    # do not display the panel if no source attached
    return if c.empty?
    context.panel (I18n.t :filter_sources), :class => "muscat_panel"  do
      # filter the list of sources
      # todo - Solr searching instead of active model searching
      # c = item.sources.where("std_title like ?", "%#{query}%") unless query.blank?
      c = Source.solr_search do
        fulltext query
        with :catalogues, item.id
        paginate :page => src_list_page, :per_page => 15 
      end
      
      #context.paginated_collection(c.page(src_list_page).per(15), param_name: 'src_list_page',  download_links: false) do
      context.paginated_collection(c.results, param_name: 'src_list_page',  download_links: false) do
        context.table_for(context.collection) do |cr|
          context.column (I18n.t :filter_composer), :composer
          context.column (I18n.t :filter_standardised_title), :std_title
          context.column (I18n.t :filter_title), :title
          context.column (I18n.t :filter_lib_siglum), :lib_siglum
          context.column (I18n.t :filter_shelf_mark), :shelf_mark
        end
      end
    end
  end 
  
  # formats the string for the source show title
  def active_admin_source_show_title( composer, std_title, id )
    return "[#{id}]" if composer.empty? and std_title.empty?
    return "#{std_title} [#{id}]" if composer.empty? and !std_title.empty?
    return "#{composer} [#{id}]" if std_title.empty?
    return "#{composer} : #{std_title} [#{id}]"
  end
  
end