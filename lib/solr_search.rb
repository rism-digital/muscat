module Muscat
  module Adapters
    module ActiveRecord
      module Base
        MAX_PER_PAGE = 30

        def get_terms(field)
          solr = Sunspot.session.get_connection
          response = solr.get "terms", :params => { :"terms.fl" => field, :"terms.limit" => -1, :"terms.mincount" => 1 }
          Hash[*response["terms"][field]].keys
        end

        def search_as_ransack(params)
          fields, order, with, page = unpack_params(params)
          per_page = params.has_key?(:per_page) ? params[:per_page] : MAX_PER_PAGE
          search_with_solr(fields, order, with, page, per_page)
        end

        def near_items_as_ransack(params, item)
          prev_item = nil
          next_item = nil
          # page values will be 0 if the prev/next item are on the same result page
          prev_page = 0
          next_page = 0
          fields, order, with, page = unpack_params(params)
          results, hits = search_with_solr(fields, order, with, page)

          position = results.index(item)

          # The current item was not found, we must be coming from somewhere else...
          return prev_item, next_item, prev_page, next_page if position == nil

          # Find the previous and next items
          # It could be condensed in one
          # but it is easyer to read like this

          # Get the prev item in the searc
          if position == 0
            if !results.first_page?
              results_prev_page, hits = search_with_solr(fields, order, with, results.previous_page)
              prev_item = results_prev_page.last
              # the previous item is one the previous page, we also need to return the page nb
              prev_page = results.previous_page
            end
          else
            prev_item = results[position - 1]
          end

          # get the next item in the search
          if position == MAX_PER_PAGE - 1
            if !results.last_page?
              results_next_page, hits = search_with_solr(fields, order, with, results.next_page)
              next_item = results_next_page.first
              # return the page number too
              next_page = results.next_page
            end
          else
            next_item = results[position + 1]
          end

          return prev_item, next_item, prev_page, next_page
        end

        private

        def search_with_solr(fields = [], order = {}, with_filter = {}, page = 1, per_page = MAX_PER_PAGE)
          model = self.to_s
          solr_results = self.solr_search do
            adjust_solr_params do |p|
              p["q.op"] = "AND"
            end

            if !order.empty?
              order_by order[:field], order[:order]
            end

            fields.each do |f|
              if f[:fields].empty?
                #without(:record_type, 2) if model=="Source"
                fulltext f[:value] do
                  exclude_fields :pae_complete
                end
              else
                #without(:record_type, 2) if model=="Source"
                fulltext f[:value], :fields => f[:fields]
              end
            end

            with_filter.each do |field, value|
              if value.is_a?(Hash)
                start_date = ApplicationHelper.to_sanitized_date(value[:start])
                end_date = ApplicationHelper.to_sanitized_date(value[:end])
                if field.to_s.match("_times")
                  with(value[:field]).between(
                    start_date..end_date
                  )
                elsif field.to_s.match("_gteq")
                  with(value[:field]).greater_than_or_equal_to(start_date)
                elsif field.to_s.match("_lteq")
                  with(value[:field]).less_than_or_equal_to(end_date)
                end
              else
                with(field, value)
              end
            end
            paginate :page => page, :per_page => per_page
          end
          return solr_results.results, solr_results.hits
        end # search_with_solr

        def unpack_params(params)
          fields = []
          order = {}
          with = {}
          page = params.has_key?(:page) ? params[:page] : 1

          if params.has_key?(:order)
            order = params[:order].include?("_asc") ? "asc" : "desc"
            field = params[:order].gsub("_#{order}", "")

            # Fields used for order by convention always end with _order
            # In some cases it is a duplicate field stored in the DB
            # So in that case we append the _order here
            if field != "id"
              field = field + "_order" if !field.ends_with?("_order") && !field.ends_with?("_shelforder")
            end

            ## HARDCODED! Shelfmarks need a particular way of indexing
            # using a custom tokenizer. If we encounter that field
            # translate it to the "special" one. The solr dynamic field
            # terminates with "*_shelforder_s"
            #if field.include
            #field = "shelf_mark_shelforder" if field == "shelf_mark_order"
            #field = "std_title_shelforder" if field == "std_title_order"

            order = { :field => field.underscore.to_sym, :order => order.to_sym }
          end

          options = params[:q]
          if options
            # These two hashes are to correlate time ranges
            time_gteq = {}
            time_lteq = {}

            options.keys.each do |k|

              # Skip to the next one if the value
              # for this query is empty
              next if options[k] == ""

              # Barebones field parser
              # Accepts only one field name
              # Whith the _contains predicate
              # E.g. :full_title_contains
              # Strip the ransack predicate
              # To do any field searches,
              # just use another predicate
              # and no field will be used
              f = []
              if k.to_s.match("contains") # :filter xxx_contains
                field = k.to_s.gsub("_contains", "")
                # split it!
                if field.include? "_or_"
                  f.concat(field.split("_or_"))
                else
                  f << field.underscore.to_sym
                end
                fields << { :fields => f, :value => options[k] }
              elsif k.to_s.match("with_integer") # :filter zzz_with_integer
                # The field to filter with is
                # in the value
                field, id = options[k].split(":")
                with[field] = id
              elsif k.to_s.match("gteq") # :Greather than time range
                field = k.to_s.gsub("_gteq_datetime", "")
                time_gteq[field] = options[k]
              elsif k.to_s.match("lteq") # :Lesser than time range
                field = k.to_s.gsub("_lteq_datetime", "")
                time_lteq[field] = options[k]
              else # all the other ransack predicates
                # make an "any" search, field is empty
                # so the value is applied to all
                fields << { :fields => [], :value => options[k] }
              end
            end

            # Consolidate the time ranges
            time_gteq.each do |param, gt|
              if time_lteq.keys.include?(param)
                with["#{param}_times"] = { field: param, start: gt, end: time_lteq[param] }
              else
                with["#{param}_gteq"] = { field: param, start: gt }
              end
            end
            time_lteq.each do |param, gt|
              if !time_gteq.keys.include?(param)
                with["#{param}_lteq"] = { field: param, end: gt }
              end
            end
          else
            # if no field is specified
            # return all elements
            fields << { :fields => [], :value => "*" }
            # If ordering is not given
            # order by id, default in sunspot is
            # by :score
            # Order descending as this is the default
            # ordering for columns in activerails
            if order.empty?
              order = { :field => :id, :order => :desc }
            end
          end

          return fields, order, with, page
        end
      end
    end
  end
end

ActiveRecord::Base.extend Muscat::Adapters::ActiveRecord::Base
