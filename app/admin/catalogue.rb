ActiveAdmin.register Catalogue do

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    def permitted_params
      params.permit!
    end
  end
  
  ###########
  ## Index ##
  ###########
  
  #scope :all, :default => true 
  #scope :published do |catalogues|
  #  catalogues.where(:wf_stage => 'published')
  #end
  
  # temporary, to be replaced by Solr
  filter :name_or_description_starts_with, :as => :string
  filter :author_contains, :as => :string
  
  index do
    selectable_column
    column (I18n.t :filter_id), :id    
    column (I18n.t :filter_name), :name
    column (I18n.t :filter_author), :author
    column (I18n.t :filter_sources), :src_count
    actions
  end
  
  ##########
  ## Show ##
  ##########
  
  show do 
    #active_admin_navigation_bar( self )
    attributes_table do
      row (I18n.t :filter_name) { |r| r.name }
      row (I18n.t :filter_author) { |r| r.author }
      row (I18n.t :filter_description) { |r| r.description }
      row (I18n.t :filter_revue_title) { |r| r.revue_title }
      row (I18n.t :filter_volume) { |r| r.volume }
      row (I18n.t :filter_date) { |r| r.date }
      row (I18n.t :filter_pages) { |r| r.pages }     
    end
    active_admin_embedded_source_list( self, catalogue, params[:q], params[:src_list_page] )
  end
  
begin  
  sidebar "Search sources", :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end
end
  
  ##########
  ## Edit ##
  ##########
  
  form do |f|
    f.inputs do
      f.input :name, :label => (I18n.t :filter_name)
      f.input :author, :label => (I18n.t :filter_author)
      f.input :description, :label => (I18n.t :filter_description)
      f.input :revue_title, :label => (I18n.t :filter_revue_title)
      f.input :volume, :label => (I18n.t :filter_volume)
      f.input :date, :label => (I18n.t :filter_date)
      f.input :pages, :label => (I18n.t :filter_pages)
    end
    f.actions
  end
  
end
