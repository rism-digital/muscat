module ActiveAdmin
  module FilterSaver
 
    # Extends the ActiveAdmin controller to persist resource index filters and pagination between requests.
    #
    # @author David Daniell / тιηуηυмвєяѕ <info@tinynumbers.com>
    # modified by Laurent Pugin
    
    module Controller
 
      private
 
      def get_saved_filters_for(tag)
        # store in the session - only for testing!
        #return session["filters"][tag] if tag && !tag.empty? && session.include?("filters") && session["filters"].include?(tag)
        
        return cookies.signed["tab-store"] if cookies.signed["tab-store"] && cookies.signed["tab-store"].is_a?(Hash)
        return session
      end

      def restore_search_filters

        # If we render via ajax, skip all this
        # Permit the "session" controller to deselect
        return if request.xhr? && controller_name != "session"
        
        # we like nice things! show it in the footer
        # Note: we need a global variable here so
        # it shows in the footer through Arbre
        @tab_id_for_footer = cookies["tab-id"]

        saved_filters = get_saved_filters_for(@tab_id_for_footer)
        puts "Using saved filters for #{@tab_id_for_footer}"

        filter_storage = saved_filters["last_search_filter"]
        pagination_storage = saved_filters["last_search_page"]
        order_storage = saved_filters["last_order_page"]
        scope_storage = saved_filters["last_scope"]
        # Do not restore filters opening the select mode
        if params.include?(:select)
          return
        end
        if params[:clear_filters]
          params.delete :clear_filters
          if filter_storage
            # This is a special case, to preserve only the record_type, if present
            # in selection mode.
            # 1. Are we in selection mode? is_selection_mode? does not work
            #    as we have to use the session param
            if session[:select] == controller_name
              saved_filters = filter_storage[controller_name]
              unless saved_filters.blank?
                if saved_filters.include?("record_type_with_integer")
                  params[:q] = {"record_type_with_integer" => saved_filters["record_type_with_integer"]}
                end
              end
            end
            
            #logger.info "clearing filter storage for #{controller_name}"
            filter_storage.delete controller_name
          end
          if pagination_storage
            #logger.info "clearing pagination storage for #{controller_name}"
            pagination_storage.delete controller_name
          end
          # comment this to avoid resetting scoping when resetting filters
          if scope_storage
            scope_storage.delete controller_name
          end
          # uncomment this to also reset order
          #if order_storage
          #  logger.info "clearing order storage for #{controller_name}"
          #  order_storage.delete controller_name
          #end
          # oppositely, we want to restore the order (if not changed)
          if order_storage && params[:order].blank?
            saved_order = order_storage[controller_name]
            unless saved_order.blank?
              params[:order] = saved_order
            end
          end
          puts "Cleared filters for #{@tab_id_for_footer}"
          cookies.signed["tab-store"] = {value: saved_filters}
        else
          restore_page = true
          # we also restore filter in :show for updating the navigation values (in preparation)
          if params[:action].to_sym == :index || params[:action].to_sym == :show || params[:action].to_sym == :batch_action
            # we have stored filters
            if filter_storage 
              # get the store filter for the controller
              saved_filters = filter_storage[controller_name]
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
              saved_page = pagination_storage[controller_name]
              unless saved_page.blank?
                params[:page] = saved_page
              end
            end
            # and order too
            if order_storage && params[:order].blank?
              saved_order = order_storage[controller_name]
              unless saved_order.blank?
                params[:order] = saved_order
              end
            end
            # and scope too
            if scope_storage && params[:scope].blank?
              saved_scope = scope_storage[controller_name]
              unless saved_scope.blank?
                params[:scope] = saved_scope
              end
            end
          end
        end
        
        if params.include?(:deselect)
          session[:select] = nil
        elsif session[:select] == controller_name 
          params[:select] = "true"
        end
        
      end

      def create_saved_filters_for(tag)
        # For testing right now, get an empty hash
        return cookies.signed["tab-store"] if cookies.signed["tab-store"] && cookies.signed["tab-store"].is_a?(Hash)
        return {}
      end

      def save_search_filters
        # as above, if we render via ajax, skip all this
        # if not in the deselection controller
        return if request.xhr? && controller_name != "session"

        saved_filters = create_saved_filters_for(cookies["tab-id"])

        session[:select] = nil
        if params[:action].to_sym == :index
          if params.include?(:q)
            saved_filters["last_search_filter"] ||= Hash.new
            saved_filters["last_search_filter"][controller_name] = params[:q]
          end
          if params.include?(:page)
            saved_filters["last_search_page"] ||= Hash.new
            saved_filters["last_search_page"][controller_name] = params[:page]
          end
          if params.include?(:order)
            saved_filters["last_order_page"] ||= Hash.new
            saved_filters["last_order_page"][controller_name] = params[:order]
          end
          if params.include?(:scope)
            saved_filters["last_scope"] ||= Hash.new
            saved_filters["last_scope"][controller_name] = params[:scope] if params.include?(:scope)
          end
          session[:select] = controller_name if params[:select]
        # We also need to save the page param in show because it might be change 
        # by the prev/next navigation 
        elsif params[:action].to_sym == :show
          saved_filters[:last_search_page] ||= Hash.new
          saved_filters[:last_search_page][controller_name] = params[:page]
          session[:select] = controller_name if params[:select]
        end

        purge_params(saved_filters)

        saved_filters["tab-id"] ||= Hash.new
        saved_filters["tab-id"] = @tab_id_for_footer

        puts "Saved filters for #{@tab_id_for_footer}"
        cookies.signed["tab-store"] = {value: saved_filters}
      end
 
      def purge_params(the_hash)
        the_hash.each do |k, v|
          if v.is_a?(Hash)
            v.delete_if {|h_key, h_value| h_value == nil}
            the_hash.delete(k) if v.empty?
          end
        end
      end
 
    end
 
  end
end