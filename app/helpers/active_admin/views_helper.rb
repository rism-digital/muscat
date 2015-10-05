# include the override for group_values
require 'sunspot_extensions.rb'

module ActiveAdmin::ViewsHelper
  
  # embedds a list of sources from a foreign (authority) model
  # - context is the show context is the AA
  # - item is the instance of the model
  # - query is the fitler for the source list
  # - src_list_page is the pagination
  def active_admin_embedded_source_list( context, item, query, src_list_page, enable_view_src = true )
    # get the list of sources for the item
    c = item.sources
    # do not display the panel if no source attached
    return if c.empty?
    context.panel (I18n.t :filter_sources), :class => "muscat_panel"  do
      
      # Sometimes if a query is already present query comes with the
      # parameters for ransack, filter this out so only text queries
      # pass
      query = "*" if !query.is_a? String
      
      # filter the list of sources
      # todo - Solr searching instead of active model searching
      # c = item.sources.where("std_title like ?", "%#{query}%") unless query.blank?
      c = Source.solr_search do
        fulltext query
        with item.class.name.underscore.pluralize.to_sym, item.id
        paginate :page => src_list_page, :per_page => 15 
      end
      
      context.paginated_collection(c.results, param_name: 'src_list_page',  download_links: false) do
        context.table_for(context.collection) do |cr|
          context.column (I18n.t :filter_composer), :composer
          context.column (I18n.t :filter_std_title), :std_title
          context.column (I18n.t :filter_title), :title
          context.column (I18n.t :filter_lib_siglum), :lib_siglum
          context.column (I18n.t :filter_shelf_mark), :shelf_mark
          if enable_view_src
            context.column "" do |source|
              link_to "View", controller: :sources, action: :show, id: source.id
            end
          end
        end
      end
    end
  end 
  
  def is_selection_mode?
    return params && params[:select].present?
  end
  
  def active_admin_user_wf( context, item )   
    context.panel (I18n.t :filter_wf) do
      context.attributes_table_for item  do
        context.row (I18n.t :filter_owner) { |r| r.user.name } if ( item.user )
        # context.row (I18n.t :created_at) { |r| I18n.localize(r.created_at, :format => '%A %e %B %Y - %H:%M') }
        context.row (I18n.t :updated_at) { |r| I18n.localize(r.updated_at.localtime, :format => '%A %e %B %Y - %H:%M') }
      end
    end
  end
  
  def active_admin_muscat_select_link( item )
    
    name = "[Model does not have a label]"
    name = item.name if item.respond_to?(:name)
    name = item.autocomplete_label if item.respond_to?(:autocomplete_label)
    
    link_to("Select", "#", :data => { :marc_editor_select => item.id, :marc_editor_label => name })
  end
  
  def active_admin_muscat_cancel_link
    link_to("Cancel", "#", :data => { :marc_editor_cancel => "cancel"})
  end
  
  def active_admin_muscat_actions( context )
    # Build the dynamic path function, then call it with send
    model = self.resource_class.to_s.underscore.downcase
    view_link_function = "admin_#{model}_path"
    if is_selection_mode?
      context.actions defaults: false do |item|
        item_links = Array.new
        item_links << link_to("View", "#{send( view_link_function, item )}")
        item_links << active_admin_muscat_select_link( item )
        safe_join item_links, ' '
      end
    else
      context.actions
    end
  end
  
  def active_admin_muscat_breadcrumb 
    return [] if is_selection_mode?
    breadcrumb_links()
  end

  # displays the navigation button on top of a show panel
  # this helper uses the controller member variables @prev_item, @next_item, @prev_page and @next_page
  # the values should be instanciated with the near_items_as_ransack from the
  def active_admin_navigation_bar( context )
    # do not display navigation if both previous and next are not available
    return if (!@prev_item && !@next_item)
    prev_id = @prev_item != nil ? @prev_item.id.to_s : ""
    next_id = @next_item != nil ? @next_item.id.to_s : ""
    prev_id += "?page=#{@prev_page}" if @prev_page != 0
    next_id += "?page=#{@next_page}" if @next_page != 0
    
    # Build the back to index path function
    model = self.resource_class.to_s.pluralize.underscore.downcase
    index_link_function = "admin_#{model}_path"
    
    context.div class: :table_tools do
      context.ul class: :table_tools_segmented_control do
        context.li class: :scope do
          if @prev_item != nil
            context.a href: prev_id, class: :table_tools_button do  context.text_node "Previous"  end
          else
            context.a class: "table_tools_button disabled" do context.text_node "Previous" end
          end
        end
        context.li class: :scope do
          context.a href: "#{send(index_link_function)}", class: :table_tools_button do  context.text_node "Back to the list"  end
        end
        context.li class: :scope do
          if @next_item != nil
            context.a href: next_id, class: :table_tools_button do  context.text_node "Next"  end
          else
            context.a class: "table_tools_button disabled" do context.text_node "Next" end
          end
        end
      end
    end
  end 
  
  # formats the string for the source show title
  def active_admin_source_show_title( composer, std_title, id )
    return "[#{id}]" if composer.empty? and std_title.empty?
    return "#{std_title} [#{id}]" if composer.empty? and !std_title.empty?
    return "#{composer} [#{id}]" if (std_title.nil? or std_title.empty?)
    return "#{composer} : #{std_title} [#{id}]"
  end
  
end
