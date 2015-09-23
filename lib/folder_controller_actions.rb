# Override collection_action so it is public
# from activeadmin lib/active_admin/resource_dsl.rb
require 'resource_dsl_extensions.rb'

MAX_FOLDER_ITEMS = 10000

# Extension module, see
# https://github.com/gregbell/active_admin/wiki/Content-rendering-API
module FolderControllerActions
  
  def self.included(dsl)
    # batch_action seems already public
    dsl.batch_action :folder, form: {
      name:   :text,
      hide:   :checkbox
    } do |ids, inputs|

      #Get the model we are working on
      model = self.resource_class
       
      # inputs is a hash of all the form fields you requested
      f = Folder.new(:name => inputs[:name], :folder_type => model.to_s)
      f.user = current_user
      f.save
      
      # Pagination is on as default! wahooo!
      params[:per_page] = 1000
      results = model.find(ids)

      f.add_items(results)
      # Quirk'o'matic of the day
      # If I call index directly on the folder items I just created
      # the index time is INFINITE, For example, on 5k folder_items:
      # Sunspot.index f.folder_items will yield:
      # Index All                   93.162000
      # Index only new FolderItems  93.174293
      # But if I force to reload the folder and the folder_items
      # the indexing time drops:
      # Index only new Folder Items 5.307983
      # Why? What is the black magic going on here?
      f2 = Folder.find(f.id)
      Sunspot.index f2.folder_items
      Sunspot.commit

      redirect_to collection_path, :notice => I18n.t(:success, scope: :folders, name: inputs[:name], count: results.count)
    end
    
    # THIS IS OVERRIDEN from resource_dsl_extensions.rb
    dsl.collection_action :save_to_folder, :method => :get do
      
      if !params.include?(:folder_name) || params[:folder_name].empty?
        redirect_to collection_path, :alert => "Please select a name for the folder."
        return
      end
      
      folder_name = params[:folder_name]
      
      #Get the model we are working on
      model = self.resource_class
      
      # Pagination is on as default! wahooo!
      params[:per_page] = 1000
      results = model.search_as_ransack(params)
      
      if results.total_entries > MAX_FOLDER_ITEMS
        redirect_to collection_path, :alert => I18n.t(:too_many, scope: :folders, max: MAX_FOLDER_ITEMS, count: results.total_entries)
        return
      end
      
      # inputs is a hash of all the form fields you requested
      f = Folder.new(:name => folder_name, :folder_type => model.to_s)
      f.user = current_user
      f.save

      all_items = []
      results.each { |s| all_items << s }
      # insert the next ones
      for page in 2..results.total_pages
        params[:page] = page
        r = Source.search_as_ransack(params)
        r.each { |s| all_items << s }
      end
      
      f.add_items(all_items)
      
      # Hack, see above
      f2 = Folder.find(f.id)
      Sunspot.index f2.folder_items
      Sunspot.commit
    
      redirect_to collection_path, :notice => I18n.t(:success, scope: :folders, name: "\"#{f.name}\"", count: all_items.count)
    end
  
    # Only show for the moment if there is a query
    dsl.sidebar 'Global Folder Actions', :only => :index, :if => proc{params.include?(:q)}, :if => proc { !is_selection_mode? } do
      # Build the dynamic path function, then call it with send
      model = self.resource_class.to_s.pluralize.underscore.downcase
      link_function = "save_to_folder_admin_#{model}_path"
      
      if params.include?(:q)
        a href: "#", onclick: "create_folder('#{send(link_function, params)}');" do text_node I18n.t(:save, scope: :folders) end
        input :class => "folder_name", placeholder: "Name", id: "folder_name"
        hr
      end
    
      ##aa_query = params[:q].split()
      # Are we selecting a folder?
      #if params[:q].include?(:id_with_integer)
      #  ul do
      #    li link_to("Action 1", "#")
      #    li link_to("Action 2", "#")
      #  end
      #end
      
    end
  
  end
  
  
end