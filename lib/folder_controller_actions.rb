# Override collection_action so it is public
# from activeadmin lib/active_admin/resource_dsl.rb
require 'patches/active_admin/resource_dsl.rb'

MAX_FOLDER_ITEMS = 200000

module ActiveAdmin

  class ResourceDSL
    
    def collection_action(name, options = {}, &block)
      action config.collection_actions, name, options, &block
    end
    
    def member_action(name, options = {}, &block)
      action config.member_actions, name, options, &block
    end
  end

end

# Extension module, see
# https://github.com/gregbell/active_admin/wiki/Content-rendering-API
module FolderControllerActions
  
  def self.included(dsl)
    # batch_action seems already public
    dsl.batch_action :folder, form: {
      name:   :text,
    } do |ids, inputs|

      #Get the model we are working on
      model = self.class.resource_class
       
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
    
    # This action adds to an existing folder, from the menu
    dsl.batch_action :add_to_folder, if: proc{ Folder.where(folder_type: self.resource_class.to_s).count > 0 }, form: -> {
      model = controller_name.classify
      folders = Folder.where(folder_type: model)
      ids = folders.map {|f| [f.name, f.id]}.collect
      {folder: ids}
    } do |ids, inputs|
      
      if !inputs[:folder]
        redirect_to collection_path, :alert => "No Folder selected."
      else
        #Get the model we are working on
        model = self.class.resource_class
        f = Folder.find(inputs[:folder])
      
        # Pagination is on as default! wahooo!
        params[:per_page] = 1000
        results = model.find(ids)

        # as above
        f.add_items(results)
        f2 = Folder.find(f.id)
        Sunspot.index f2.folder_items
        Sunspot.commit

        redirect_to collection_path, :notice => I18n.t(:added, scope: :folders, name: f.name, count: results.count)
      end
    end
    
    dsl.batch_action :remove_from_folder, confirm: "Are you sure?", if: proc{ is_folder_selected?} do |ids, input|

      folder_id = get_folder_from_params
      
      if !folder_id
        redirect_to collection_path, :alert => "No Folder selected."
      else
        
        begin
          f = Folder.find(folder_id)
          
          if cannot?(:manage, f)
            redirect_to collection_path, :alert => "You are not authorized to remove items from #{f.name} (#{f.id})."
          else
            f.remove_items(ids)
            redirect_to collection_path, :notice => "Removed #{ids.count} from folder #{f.name} (#{f.id})"
          end
          
        rescue ActiveRecord::RecordNotFound
          redirect_to collection_path, :alert => "Folder #{folder_id} does not exist."
        end
        
      end
    end
    
    # THIS IS OVERRIDEN from resource_dsl_extensions.rb
    dsl.collection_action :do_create_new_folder, :method => :get do
      
      if !params.include?(:folder_name) || params[:folder_name].empty?
        redirect_to collection_path, :alert => "Please select a name for the folder."
        return
      end
      
      #Get the model we are working on
      model = self.class.resource_class
      
      params[:per_page] = 1000
      results, hits = model.search_as_ransack(params)
      
      if results.total_entries > MAX_FOLDER_ITEMS
        redirect_to collection_path, :alert => I18n.t(:too_many, scope: :folders, max: MAX_FOLDER_ITEMS, count: results.total_entries)
        return
      end
      
      folder_name = params[:folder_name]
      f = Folder.new(:name => folder_name, :folder_type => model.to_s)
      f.user = current_user
      f.save
       
      job = Delayed::Job.enqueue(AddToFolderJob.new(f.id, params, model))
        
      redirect_to collection_path, :notice => I18n.t(:success_bg, scope: :folders, name: "\"#{f.name}\"", job: job.id)
    end
    
    dsl.collection_action :do_append_to_folder, :method => :get do
      
      if !params.include?(:folder) || params[:folder].empty?
        redirect_to collection_path, :alert => "Please select a name for the folder."
        return
      end
            
      #Get the model we are working on
      model = self.class.resource_class
      
      # Pagination is on as default! wahooo!
      params[:per_page] = 1000
      results, hits = model.search_as_ransack(params)
      
      if results.total_entries > MAX_FOLDER_ITEMS
        redirect_to collection_path, :alert => I18n.t(:too_many, scope: :folders, max: MAX_FOLDER_ITEMS, count: results.total_entries)
        return
      end
      
      # inputs is a hash of all the form fields you requested
      f = Folder.find(params[:folder])

      job = Delayed::Job.enqueue(AddToFolderJob.new(f.id, params, model))

      redirect_to collection_path, :notice => I18n.t(:added_bg, scope: :folders, name: "\"#{f.name}\"", job: job.id)
    end
    
    ## Shows a page so the user can select the folder name
    dsl.collection_action :create_new_folder, :method => :get do
      
      if !params || !params.include?(:q)
        redirect_to collection_path, :flash => {error: "Please include a query before creating a folder"}
        return
      end
      
      #Get the model we are working on
      @model = self.class.resource_class
            
      model_downcase = self.class.resource_class.to_s.pluralize.underscore.downcase
      link_function = "do_create_new_folder_admin_#{model_downcase}_path"
      
      # Pagination is on as default! wahooo!
      params[:per_page] = 1000
      results, hits = @model.search_as_ransack(params)
      
      @items_count = results.total_entries
      @save_path = send(link_function)
    end 
    
    dsl.collection_action :append_to_folder, :method => :get do
      #Get the model we are working on
      @model = self.class.resource_class
      
      model_downcase = self.class.resource_class.to_s.pluralize.underscore.downcase
      link_function = "do_append_to_folder_admin_#{model_downcase}_path"
      
      # Pagination is on as default! wahooo!
      params[:per_page] = 1000
      results, hits = @model.search_as_ransack(params)
      
      @items_count = results.total_entries
      @save_path = send(link_function)
    end

    dsl.member_action :remove_item_from_folder, :method => :delete do
      folder_id = params.permit(:folder_id)[:folder_id]
      item_id = params.permit(:id)[:id]
      if !folder_id
        redirect_to resource_path(item_id), alert: "No Folder selected"
      else
        begin
          f = Folder.find(folder_id)
          if cannot?(:manage, f)
            redirect_to resource_path(item_id), alert: "You are not authorized to remove items from #{f.name} #{f.id}"
          else
            f.remove_items([item_id])
            redirect_to resource_path(item_id), notice: "Removed 1 element from folder #{f.name} #{f.id}"
          end
        rescue ActiveRecord::RecordNotFound
          redirect_to collection_path, alert: "Folder #{folder_id} does not exist"
        end
      end
    end
    
    dsl.member_action :add_item_to_folder, method: :post do
      folder_id = params.permit(:folder_id)[:folder_id]
      model = params.permit(:model)[:model]
      item_id = params.permit(:item_id)[:item_id]
      item = model.constantize.find(item_id)
      if !folder_id
        redirect_to resource_path(item_id), alert: "No Folder selected"
      else
        begin
          f = Folder.find(folder_id)
          if cannot?(:manage, f)
            redirect_to resource_path(item_id), alert: "You are not authorized to add items to #{f.name} #{f.id}"
          else
            f.add_items([item])
            f.reload
            f2 = Folder.find(f.id)
            Sunspot.index f2.folder_items
            Sunspot.commit
            redirect_to resource_path(item), notice: I18n.t(:added, scope: :folders, name: f.name, count: 1)
          end
        rescue ActiveRecord::RecordNotFound
          redirect_to collection_path, alert: "Folder #{folder_id} does not exist"
        end
      end
    end
  end
end
