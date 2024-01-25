Rails.application.routes.draw do
  root :to => redirect(RISM::ROOT_REDIRECT)
	
  ##############################
  
  devise_for :users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  
  #scope ':locale', locale: I18n.locale do
  #  ActiveAdmin.routes(self)
  #end

  if RISM::SAML_AUTHENTICATION && %(development test).include?(Rails.env)
    get 'test/saml/idp/auth' => 'test/saml_idp#new'
    post 'test/saml/idp/auth' => 'test/saml_idp#create'
  end
  
  get "/manuscripts", to: redirect('/sources')
  get "/manuscripts/:name", to: redirect('/sources/%{name}')

  get "/sources", to: redirect('/admin/sources')
  get "/sources/:name", to: redirect('/admin/sources/%{name}')

  ## Set up routes to redirect legacy /pages from muscat2
  ## to the new site URL
  get '/pages', to: redirect(RISM::LEGACY_PAGES_URL)
  get '/pages/:name', to: redirect(RISM::LEGACY_PAGES_URL + '/pages/%{name}')

  get 'sru' => 'sru#service'
  get 'sru/sources' => 'sru#service'
  # To have backward compatibility with the old interface
  get 'muscat' => 'sru#service'
  get 'sru/people' => 'sru#service'
  get 'sru/institutions' => 'sru#service'
  get 'sru/publications' => 'sru#service'
  get 'sru/catalogues' => 'sru#service'
  get 'sru/works' => 'sru#service'

  ##############################
  ### Routes for the GND editor implemented in the /admin/gnd_works page
  get 'admin/gnd_works/new' => 'admin/gnd_works#new'
  get 'admin/gnd_works/edit' => 'admin/gnd_works#edit'
  get 'admin/gnd_works/search' => 'admin/gnd_works#search'
  post 'admin/gnd_works/marc_editor_validate' => 'admin/gnd_works#marc_editor_validate'
  post 'admin/gnd_works/marc_editor_save' => 'admin/gnd_works#marc_editor_save'
  get 'admin/gnd_works/autocomplete_gnd_works_person' => 'admin/gnd_works#autocomplete_gnd_works_person'
  get 'admin/gnd_works/autocomplete_gnd_works_instrument' => 'admin/gnd_works#autocomplete_gnd_works_instrument'
  get 'admin/gnd_works/autocomplete_gnd_works_form' => 'admin/gnd_works#autocomplete_gnd_works_form'

  # MarcXML endpoint
  get '/data/:model/:id' => "data#show"
  match '*data', :to => 'data#routing_error', via: :all


  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end
  
  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
