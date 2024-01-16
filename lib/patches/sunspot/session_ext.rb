# Monkey patch the Sunspot Session
# To get the RSolr connection object

# Open the Session class and add a public
# function that returns the connection. Note
# we call the private connection function which
# connects to RSolr if needed

module Sunspot
  class Session
    def get_connection
      connection
    end
  end
end