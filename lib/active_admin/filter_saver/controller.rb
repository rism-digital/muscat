module ActiveAdmin
  module FilterSaver
 
    # Extends the ActiveAdmin controller to persist resource index filters and pagination between requests.
    #
    # @author David Daniell / тιηуηυмвєяѕ <info@tinynumbers.com>
    # modified by Laurent Pugin
    
    module Controller
 
      private
 
      SAVED_FILTER_KEY = :last_search_filter
      SAVED_PAGINATION_KEY = :last_search_page
      SAVED_ORDER_KEY = :last_order_page
 
      def restore_search_filters
        filter_storage = session[SAVED_FILTER_KEY]
        pagination_storage = session[SAVED_PAGINATION_KEY]
        order_storage = session[SAVED_ORDER_KEY]
        if params[:clear_filters].present?
          params.delete :clear_filters
          if filter_storage
            #logger.info "clearing filter storage for #{controller_key}"
            filter_storage.delete controller_key
          end
          if pagination_storage
            #logger.info "clearing pagination storage for #{controller_key}"
            pagination_storage.delete controller_key
          end
          # uncomment this to also reset order
          #if order_storage
          #  logger.info "clearing order storage for #{controller_key}"
          #  order_storage.delete controller_key
          #end
          if request.post?
            # we were requested via an ajax post from our custom JS
            # this render will abort the request, which is ok, since a GET request will immediately follow
            render json: { filters_cleared: true }
          end
        else
          restore_page = true
          if params[:action].to_sym == :index
            # we have stored filters
            if filter_storage 
              # get the store filter for the controller
              saved_filters = filter_storage[controller_key]
              # we have nothing in the query, retore if not empty
              if params[:q].blank?
                unless saved_filters.blank?
                  params[:q] = saved_filters
                end
              # else, we need to check if the filter changed. If yes, don't restore the pagination
              elsif params[:q] != saved_filters
                restore_page = false
              end
            end
            # restore the pagination in the same way
            if pagination_storage && params[:page].blank? && restore_page
              saved_page = pagination_storage[controller_key]
              unless saved_page.blank?
                params[:page] = saved_page
              end
            end
            # and order too
            if order_storage && params[:order].blank?
              saved_order = order_storage[controller_key]
              unless saved_order.blank?
                params[:order] = saved_order
              end
            end
          end
        end
      end
 
      def save_search_filters
        if params[:action].to_sym == :index
          session[SAVED_FILTER_KEY] ||= Hash.new
          session[SAVED_FILTER_KEY][controller_key] = params[:q]
          session[SAVED_PAGINATION_KEY] ||= Hash.new
          session[SAVED_PAGINATION_KEY][controller_key] = params[:page]
          session[SAVED_ORDER_KEY] ||= Hash.new
          session[SAVED_ORDER_KEY][controller_key] = params[:order]
        end
      end
 
      # Get a symbol for keying the current controller in the saved-filter session storage.
      def controller_key
        #params[:controller].gsub(/\//, '_').to_sym
        current_path = request.env['PATH_INFO']
        current_route = Rails.application.routes.recognize_path(current_path)
        current_route.sort.flatten.join('-').gsub(/\//, '_').to_sym
      end
 
    end
 
  end
end