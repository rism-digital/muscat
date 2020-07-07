# This class is a workaround to execute Blacklight queries on the backend
# In some cases (i.e. export jobs) there is the necessiry to run the same
# identical query as the user (with facets) to get the exact results as
# the web page. In "normal" Muscat we can call the search interface directly
# but Blacklight does not expose the internal searching functionality, this
# meas we have to use ActionDispatch::Integration::Session to simulate http
# requests to the controller. Another way would be to instantiate the
# CatalogController, but that is quite complex to do since it carries a lot
# of environment with it.
# The only problem is that since we simulate http requests, we also need to
# simulate a session login if /catalog is protected by password. To do this
# any user can be used, but a specialized dummy one is better.
# See ApplicationController#auth_user to disable user login
class CatalogSearch < Object
    PER_PAGE = 2000

    def initialize(user = nil, pass = nil, controller = nil)
        @user = user
        @pass = pass
        @logged_in = false
        @controller = controller ? "_" + controller : ""
        @csrf_token
        @app = ActionDispatch::Integration::Session.new(Rails.application)
    end

    def login_app
        return if @logged_in || (!@user || !@pass)

        # Get a csrf_token
        @app.get '/admin/login'
        @csrf_token = @app.session.to_hash["_csrf_token"]

        # We need to login with a dummy user
        @app.post('/admin/login', params: {"authenticity_token" => @csrf_token, 'user[email]' => @user, 'user[password]' => @pass})
        # We should be logged in now
        @logged_in = true
    end

    def search(params)
        output = []
        # Login if we are not, provided we have a user and a pass
        # if not, assume we are doing a guest login
        login_app if !@logged_in && @user && @pass

        # get the first page
        docs, pages = query_catalog(params, 1)
        return if !docs || !pages

        output += docs2ids(docs)
        total_pages = pages["total_pages"]

        # get the remainig pages
        if total_pages > 1
            for page in 2..total_pages
                docs, pages = query_catalog(params, page)
                next if !docs || !pages
                output += docs2ids(docs)
            end
        end

        return output
    end

    def query_catalog(params, page)
        @app.post("/catalog#{@controller}.json", params: params.merge({per_page: PER_PAGE, page: page}))

        catalog_response = JSON.parse(@app.response.body)
  
        return if !catalog_response
        return if !catalog_response["response"]
        return if !catalog_response["response"]["docs"]
        
        return [catalog_response["response"]["docs"], catalog_response["response"]["pages"]]  
      end
  
    def docs2ids(docs)
        ids = []
        docs.each do |doc|
          type, id = doc["id"].split(" ")
          next if type != "Source"
          ids << id.to_i
        end
        
        return ids
    end

end