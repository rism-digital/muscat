# include the override for group_values
# FIXME on rails 7.0, do we still need this?
#require 'patches/sunspot/search/paginated_collection.rb'

module ActiveAdmin::ViewsHelper
  
  # This is repeated the same everywhere, so we just make one function with the contents
  def active_admin_embedded_source_list(context, item, enable_view_src = true)
    # The columns should be the same for every list in every page!
    active_admin_embedded_link_list(context, item, Source) do |context|
      context.table_for(context.collection) do |cr|
        context.column "id", :id
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
	
  def active_admin_embedded_link_list(context, item, link_class, panel_title = nil, &block)
    current_page_name = link_class.to_s.downcase + "_list_page"
    current_page = params[current_page_name]
    #if link_class == Source && item.respond_to?("referring_sources") && item.respond_to?("referring_holdings")
    #  c = Source.where(id: item.referring_sources.ids).or(Source.where(id: item.referring_holdings.pluck(:source_id)))
    #elsif link_class == Source && item.respond_to?("referring_sources") && item.is_a?(Institution)
    #  c = Source.where(id: item.referring_sources.ids).or(Source.where(id: item.holdings.pluck(:source_id)))
    if link_class == InventoryItem &&item.respond_to?("inventory_items") && item.is_a?(Source)
      c = item.inventory_items
    else
      c = item.send("referring_" + link_class.to_s.pluralize.underscore)
    end    
    # do not display the panel if no source attached
    return if c.empty?
    panel_title = I18n.t(:refers_to_this, model_from: link_class.model_name.human(count: 2), model_to: item.model_name.human) if !panel_title
    
    context.panel panel_title, :class => "muscat_panel"  do
      context.paginated_collection(c.page(current_page).per(10), param_name: current_page_name,  download_links: false) do
        yield(context)
      end
    end
  end 
 
  def active_adnin_create_list_for(context, model, item, *fields)
    controller_name = model.name.underscore.downcase.pluralize.to_sym
    active_admin_embedded_link_list(context, item, model) do |context|
      context.table_for(context.collection) do |cr|
        context.column "id", :id
        fields.first.each do |field, label|
          context.column label, field
        end
        if !is_selection_mode?
          context.column "" do |ti|
            link_to "View", controller: controller_name, action: :show, id: ti.id
          end
        end
      end
    end
  end

  def is_selection_mode?
    return params && params[:select].present?
  end
  
  def is_folder_selected?
    return params && params[:q].present? && params[:q][:id_with_integer].present? && params[:q][:id_with_integer].include?("folder_id:")
  end

  def get_filter_record_type
    if params.include?(:q) && params[:q].include?("record_type_with_integer")
      params[:q]["record_type_with_integer"]
    end
  end

  def active_admin_user_wf( context, item )   
    context.panel (I18n.t :filter_wf) do
      context.attributes_table_for item  do
        context.row (I18n.t :filter_owner) { |r| r.user.name } if ( item.user )
        context.row (I18n.t :filter_wf_stage) { |r| I18n.t("wf_stage.#{r.wf_stage}") } if ( item.wf_stage )
        context.row (I18n.t :"general.validity") { |r| r.wf_audit.to_s.capitalize } if ( item.is_a?(Work) && item.wf_audit != "normal" ) # I know I know will be translated if needed, #1532
        context.row (I18n.t 'helpers.label.folder.work_catalogue_status') { |r| I18n.t("work_catalogue_labels." + r.work_catalogue) } if ( item.is_a?(Publication) && item.work_catalogue && can?(:edit, Work) )
        context.row (I18n.t :created_at) { |r| I18n.localize(r.created_at ? r.created_at.localtime : "", :format => '%A %e %B %Y - %H:%M') }
        context.row (I18n.t :updated_at) { |r| I18n.localize(r.updated_at ? r.updated_at.localtime : "", :format => '%A %e %B %Y - %H:%M') }
      end
    end
  end
  
  def active_admin_muscat_select_link( item )
    
    name = "[Model does not have a label]"
    name = item.name if item.respond_to?(:name)
    name = item.full_name if item.respond_to?(:full_name)
    name = item.title if item.respond_to?(:title)
    name = item.autocomplete_label if item.respond_to?(:autocomplete_label)
    name = item.formatted_title if item.respond_to?(:formatted_title)

    link_to("Select", "#", :data => { :marc_editor_select => item.id, :marc_editor_label => name })
  end
  
  def active_admin_muscat_actions( context, show_view = true )
    # Build the dynamic path function, then call it with send
    model = self.resource_class.to_s.underscore.downcase
    view_link_function = "admin_#{model}_path"
    if is_selection_mode?
      context.actions defaults: false do |item|
        item_links = Array.new
        item_links << link_to("View", "#{send( view_link_function, item )}") if show_view
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
          context.a class: "table_tools_button" do context.text_node "#{@nav_positions[:position]}/#{@nav_positions[:total]}" end
        end
      end

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
  def active_admin_source_show_title( composer, std_title, id, record_type )
    record_type = record_type ? "#{I18n.t('record_types.' + record_type.to_s)} " : ""
    return "#{record_type}[#{id}]" if !composer or std_title
    return "#{record_type}[#{id}]" if composer.empty? and std_title.empty?
    return "#{std_title} - #{record_type}[#{id}]" if composer.empty? and !std_title.empty?
    return "#{composer} - #{record_type}[#{id}]" if (std_title.nil? or std_title.empty?)
    return "#{composer} : #{std_title} - #{record_type}[#{id}]"
  end
  
  # formats the string for the holding show title
  def active_admin_holding_show_title( holding )
    return "#{holding.lib_siglum}[#{holding.id}]" if !holding.source
    return "#{holding.lib_siglum}[#{holding.id}] (#{holding.source.std_title}[#{holding.source.id}])"if !holding.source.composer
    return "#{holding.lib_siglum}[#{holding.id}] (#{holding.source.composer}[#{holding.source.id}])" if !holding.source.std_title
    return "#{holding.lib_siglum}[#{holding.id}] (#{holding.source.composer} - #{holding.source.std_title}[#{holding.source.id}])"
  end
  
  # formats the string for the source show title
  def active_admin_auth_show_title( val1, val2, id )
    val1 = "" if !val1
    val2 = "" if !val2
    return "[#{id}]" if val1.empty? and val2.empty?
    return "#{val2} - [#{id}]" if val1.empty? and !val2.empty?
    return "#{val1} - [#{id}]" if (val2.nil? or val2.empty?)
    return "#{val1} : #{val2} - [#{id}]"
  end
 
  def active_admin_publication_show_title( author, title, id )
    return "[#{id}]" if author&.empty? and title&.empty?
    return "#{title} [#{id}]" if author&.empty? and !title&.empty?
    return "#{author} [#{id}]" if (title.nil? or title&.empty?)
    return "#{author} : #{title} [#{id}]"
  end
  
  def active_admin_digital_object_show_title( description, id )
    return "[#{id}]" if !description || description.empty?
    return "#{description.truncate(60)} - [#{id}]"
  end
  
  def active_admin_inventory_item_show_title (ii)
    ii.title
  end

  def digital_object_form_url
    parts = []
    parts << active_admin_namespace.name unless active_admin_namespace.root?
    parts << "digital_objects_path"
    send parts.join '_'
  end
  
  def filesize_to_human value
    units = %w{B KB MB GB TB}
    e = (Math.log(value)/Math.log(1024)).floor
    s = "%.1f" % (value.to_f / 1024**e)
    s.sub(/\.?0*$/, units[e])
  end
  
  def active_admin_digital_object( context, item )   
    if item.digital_objects.images.size > 0 
      context.panel (I18n.t :digital_objects) do
        item.digital_objects.images.each do |obj| 
          context.attributes_table_for obj do 
            context.row (I18n.t :filter_description) { |r| r.description } 
            context.row (I18n.t :filter_image) { |obj| 
              link_to(image_tag(obj.attachment.url(:medium)), admin_digital_object_path(obj)) }
          end
        end
      end
    end
    
    # The block below create a input form for digital objects when it was attached directly to the source
    # not used anymore because now we have a many to many relationship + polymorphic. 
    # Digital objects are added from the edit menu
    # Left for documentation because it was a pain to have it up....
    
    #context.panel (I18n.t :digital_object_new) do
    #  active_admin_form_for(DigitalObject.new, url: digital_object_form_url, html: { multipart: true }) do |f|
    #  #context.form :html => {:multipart => true} do |f|
    #    f.inputs do
    #      f.input :source_id, :as => :hidden, :input_html => {:value => item.id }
    #      f.input :description, :label => I18n.t(:filter_description)
    #      f.input :attachment, as: :file, hint: (f.template.image_tag(f.object.attachment.url(:thumb)) if f.object.attachment?), :label => I18n.t(:filter_image)
     #   end
    #    f.actions do
    #      f.action :submit, label: I18n.t(:digital_object_add)
    #    end
    #  end
    #end
    
  end

  def active_admin_stored_from_hits(all_hits, object, field)
    hits = all_hits.select {|h| h.to_param == object.id.to_s}
    if hits && hits.count > 0
      hits.first.stored(field).to_s
    end
  end

  def local_sorting( codes, editor_profile )
    local_hash = Hash.new
    codes.each do |code|
      local_hash[code] = editor_profile.get_label(code)
    end
    # To disable unicode sorting, user sort_by here
    # This call uses the sort_alphabetical gem
    return Hash[local_hash.sort_alphabetical_by{|k, v| v.downcase}].keys
  end
	
  def pretty_truncate(text, length = 30, truncate_string = "...")
    return if text.nil?
    l = length - truncate_string.mb_chars.length
    text.mb_chars.length > length ? text[/\A.{#{l}}\w*\;?/m][/.*[\w\;]/m] + truncate_string : text
  end

  def dashboard_comment_record_exists(resource_type, resource_id)
    begin
      item = resource_type.constantize.find(resource_id)
      return item
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end

  def dashboard_find_recent(model, limit, modification, user, days = 7) 
    if modification == :updated
      modif_at = "updated_at"
    else
      modif_at = "created_at"
    end

    if user != -1
      model.where((modif_at + " > ?"), days.days.ago).where("wf_owner = ?", user).limit(limit).order(modif_at + " DESC")
    else
      model.where((modif_at + "> ?"), days.days.ago).limit(limit).order(modif_at + " DESC") 
    end
  end

  def dashboard_find_unpublished(model, limit, user)
    if user != -1
      src = model.where(wf_stage: :inprogress).where("wf_owner = ?", user).limit(limit).order("id DESC")
      count = model.where(wf_stage: :inprogress).where("wf_owner = ?", user).count
    else
      src = model.where(wf_stage: :inprogress).limit(limit).order("id DESC")
      count = model.where(wf_stage: :inprogress).count
    end
    return src, count
  end

  def dashboard_get_model_comments(limit, days = 7)
    comments =  ActiveAdmin::Comment.where(("updated_at > ? AND namespace = 'admin'"), days.days.ago)
    return comments.collect {|c|
      item = dashboard_comment_record_exists(c.resource_type, c.resource_id)
      if item
        c if item.wf_owner == current_user.id
      else
        c ## Oops! The item was deleted! Still send the comment so we can mark it...
      end
    }.compact.first(limit)
  end

  def dashboard_get_referring_comments(limit, days = 7)
    sanitized_name = current_user.name.gsub(" ", "_")
    user_name = "@#{sanitized_name}"

    ActiveAdmin::Comment.where(("updated_at > ? AND namespace = 'admin'"), days.days.ago).where("body LIKE '%#{user_name}%'").limit(limit)
  end

  def dashboard_get_my_comments(limit, days = 7)
    ActiveAdmin::Comment.where(("updated_at > ? AND namespace = 'admin'"), days.days.ago).where(author_id: current_user.id).limit(limit)
  end

  def dashboard_make_comment_section(context, items, title)

    context.columns do
      context.column do
        context.panel title do
          if items.count > 0
            context.table_for items.map do
              context.column (I18n.t :filter_date), :created_at
              context.column (I18n.t :filter_author), :author
              context.column (I18n.t :filter_comment), :body do |comment|
                link_to comment.body, admin_comment_path(comment)
              end
              context.column (I18n.t :object) do |r|
                localized_model = I18n.t(r.resource_type.downcase + ".one").capitalize # The model kay is not underscored in the translation file
                if dashboard_comment_record_exists(r.resource_type, r.resource_id)
                  link_to "#{localized_model} #{r.resource_id}", controller: r.resource_type.pluralize.underscore.downcase.to_sym, action: :show,  id: r.resource_id
                else
                  context.status_tag(:deleted, label: I18n.t("wf_stage.deleted"))
                  context.text_node("#{localized_model} #{r.resource_id}")
                end
              end
            end
          else
            context.text_node(I18n.t('dashboard.no_items'))
          end
        end
      end
    end

  end

  def diff_find_in_interval(model, user, interval, index)
    results = {}
    sql_interval = interval == "week" ? 7.days.ago : 1.days.ago
    rule_index = index != nil ? index.to_i : 0

    model = NotificationMatcher::get_model_for_rule(rule_index, user)
    return {} if !model


    model.where(("updated_at" + "> ?"), sql_interval).order("updated_at DESC").each do |s|
      matcher = NotificationMatcher.new(s, user, rule_index)
      matcher.get_matches.each do |match|
        results[match] = [] if !results[match]

        results[match] << s
      end
    end
    return results, model
  end

  def active_admin_work_status_tag_class value
    return "" if !value
    c = 0
    while value > 0
      value &= value - 1
      c += 1
    end
    return "links-#{c}"
  end

  def active_admin_work_status_tag_label value
    return "" if !value
    s = []
    s << "DNB" if (value & 1) > 0
    s << "BNF" if (value & 2) > 0
    s << "MBZ" if (value & 4) > 0
    return s.join(' ')
  end

end
