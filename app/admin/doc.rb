ActiveAdmin.register_page "doc" do
  
  controller do
    def index
      @model_name = params[:model].downcase
      klass = params[:model].classify.safe_constantize

      @model = klass != nil ? klass.new : nil
    end
  end
  
  content do
    render partial: 'fields'
  end
end