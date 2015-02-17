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
    
    # Monkey patch the Sunspot Session
    # To get the RSolr connection object
    
    # Open the Session class and add a public
    # function that returns the connection. Note
    # we call the private connection function which
    # connects to RSolr if needed
    class Session
      def get_connection
        connection
      end
    end
    
    # The session class is not called directly but proxied
    # The default proxy is the Threaded one, which delegates
    # all the methods back to Session. We need to add
    # a delegate for our new get_connection
    module SessionProxy
      class ThreadLocalSessionProxy
        delegate :get_connection, :to => :session
      end
    end
    
  end
