ActiveAdmin.register_page "doc" do
  
  controller do
    def index
      @model_name = params[:model].downcase
      klass = params[:model].classify.safe_constantize
      
      @model = klass != nil ? klass.new : nil
      
    end
  end
  
  content do
    if @model != nil
      render partial: 'fields'
    else
      para "Please specify a valid model."
    end
  end
end