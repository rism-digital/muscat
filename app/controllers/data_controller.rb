# curl -H "Authorization: Token TEST" -H "Accept: application/xml" -H -X GET http://localhost:3000/data/sources/1

class DataController < ActionController::Base
    MODELS=["sources", 
            "holdings",
            "institutions",
            "liturgical_feasts",
            "publications", 
            "people",
            "works",
            "work_nodes"]

    before_action :authenticate

    rescue_from ActiveRecord::RecordNotFound, :with => :resource_not_found

    def show
        if !MODELS.include?(params[:model])
            model_not_found
            return false
        end

        @model = params[:model].classify.safe_constantize
        @item = @model.find(params[:id])

        @deprecated_ids = params.include?("deprecatedIds") ? params["deprecatedIds"] : "false"

        ap params
        ap params["deprecatedIds"]

        if @item.respond_to?(:marc)
            @xml = @item.marc.to_xml({ updated_at: @item.updated_at, versions: @item.versions, deprecated_ids: @deprecated_ids })
        else
            @xml = @item.to_xml
        end

        respond_to do |format|
            format.xml { render :xml => @xml }
        end
    end

    def index
    end

    def resource_not_found
        respond_to do |format|
          format.xml{  render :xml => 'Record Not Found', :status => 404 }
          format.json{ render :json => 'Record Not Found',  :status => 404 }
        end
      end
    
      def model_not_found
        respond_to do |format|
          format.xml{  render :xml => 'Resource Not Found', :status => 404 }
          format.json{ render :json => 'Resource Not Found', :status => 404 }
        end
      end

      def routing_error
        respond_to do |format|
          format.xml{  render :xml => 'Method Not Allowed', :status => 405 }
          format.json{ render :json => 'Method Not Allowed', :status => 405 }
        end
      end

    private

    def authenticate
        authenticate_or_request_with_http_token do |token, options|
            toks = AuthorizationToken.where(active: true)
            found = false
            toks.each do |tok|
                res = ActiveSupport::SecurityUtils.secure_compare(token, tok.token)
                found = true if res
            end
            found
        end
    end

    def current_user
        @current_user ||= authenticate
    end

end
