  module Sunspot
    module Search

      class PaginatedCollection
        # Used by AA in collections.rb
      	def group_values
          return []
      	end
      
        # For compatibility with hash
        # http://apidock.com/rails/Hash/except
        # Used by AA in collections.rb
        def except(*keys)
          self
        end
      
      end
    end
  end
