# The session class is not called directly but proxied
# The default proxy is the Threaded one, which delegates
# all the methods back to Session. We need to add
# a delegate for our new get_connection
module Sunspot    
  module SessionProxy
    class ThreadLocalSessionProxy < AbstractSessionProxy #< Sunspot::SessionProxy::AbstractSessionProxy
      delegate :get_connection, :to => :session
    end
  end
end