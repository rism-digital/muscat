# Override collection_action so it is public
# from activeadmin lib/active_admin/resource_dsl.rb
require 'resource_dsl_extensions.rb'

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
      f = Folder.create(:name => inputs[:name], :folder_type => model.to_s)
      # Pagination is on as default! wahooo!
      params[:per_page] = 1000
      results = model.find(ids)

      results.each { |s| f.add_item(s) }

      redirect_to collection_path, :notice => I18n.t(:success, scope: :folders, name: inputs[:name], count: results.count)
    end
    
    # THIS IS OVERRIDEN from resource_dsl_extensions.rb
    dsl.collection_action :save_to_folder, :method => :get do
      
      #Get the model we are working on
      model = self.resource_class
      
      # inputs is a hash of all the form fields you requested
      f = Folder.create(:name => "Folder #{Folder.count}", :folder_type => model.to_s)
      # Pagination is on as default! wahooo!
      params[:per_page] = 1000
      results = model.search_as_ransack(params)

      # do everything in one transaction - however, we should put a limit on this
      ActiveRecord::Base.transaction do
        results.each { |s| f.add_item(s) }
        # insert the next ones
        for page in 2..results.total_pages
          params[:page] = page
          r = Source.search_as_ransack(params)
          r.each { |s| f.add_item(s) }
        end
      end
    
      redirect_to collection_path, :notice => I18n.t(:success, scope: :folders, name: "\"#{f.name}\"", count: results.total_entries)
    end

    dsl.action_item :if => proc {params.include?(:q)} do
      # Build the dynamic path function, then call it with send
      model = self.resource_class.to_s.pluralize.downcase
      link_function = "save_to_folder_#{model}_path"
      
      link_to(I18n.t(:save, scope: :folders), send(link_function, params))
    end
  
  end
  
  
end