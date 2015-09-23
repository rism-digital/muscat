ActiveAdmin.register Work do
  
  menu false

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    def permitted_params
      params.permit!
    end
    
    after_destroy :check_model_errors
    before_create do |item|
      item.user = current_user
    end
    
    def check_model_errors(object)
      return unless object.errors.any?
      flash[:error] ||= []
      flash[:error].concat(object.errors.full_messages)
    end
    
    def show
      @work = Work.find(params[:id])
      @prev_item, @next_item, @prev_page, @next_page = Work.near_items_as_ransack(params, @work)
    end
    
    def index
      @results = Work.search_as_ransack(params)
      
      index! do |format|
        @works = @results
        format.html
      end
    end
    
  end
  
  ###########
  ## Index ##
  ###########
  
  # Solr search all fields: "_equal"
  filter :title_equals, :label => "Any field contains", :as => :string
  
end
