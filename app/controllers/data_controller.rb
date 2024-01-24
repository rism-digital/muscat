# curl -H "Accept: application/xml" -H "Content-Type: application/xml" -X GET http://localhost:3000/data/sources/1
# curl -H "Authorization: Token TEST" -H "Accept: application/xml" -H "Content-Type: application/xml" -X GET http://localhost:3000/data/sources/1

class DataController < ActionController::Base
    TOKEN="TEST"

    MODELS=["sources", 
            "holdings",
            "institutions",
            "liturgical_feasts",
            "publications", 
            "people", 
            "standard_titles", 
            "standard_term", 
            "standard_titles",
            "works",
            "work_nodes"]

    before_action :authenticate

    def show
        if !MODELS.include?(params[:model])
            return false
        end

        @model = params[:model].classify.safe_constantize

        @item = @model.find(params[:id])
        respond_to do |format|
            format.xml { render :xml => @item.marc.to_xml({ updated_at: @item.updated_at, versions: @item.versions }) }
        end
    end

    def index
    end

    private

    def authenticate
        authenticate_or_request_with_http_token do |token, options|
        ActiveSupport::SecurityUtils.secure_compare(token, TOKEN)
        end
    end

    def current_user
        @current_user ||= authenticate
    end

end
