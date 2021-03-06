SocialIslands::Application.routes.draw do

  match '/v0.9/trust_check' => 'api#trust_check', via: [:post, :put]

  get  '/v0.9/trust_check' => lambda { |env|
    msg = {errors: {base: "You must use POST requests to use this interface"}}.to_json
    [405, {'Content-Length'=>msg.length.to_s,'Content-Type'=>'application/json', 'Allow'=>'POST, PUT'}, [msg]]
  }

  get '/faq' => 'pages#faq'

  # Omniauth routes
  match '/auth/:provider/callback' => 'sessions#create'
  match '/auth/failure' => 'sessions#failure'
  match 'sign_out' => 'sessions#destroy'

  resource :facebook_profile, path: 'facebook', only: 'show' do
    collection do
      get :graph
      get :png
      put :label
    end
  end

  namespace :dashboard do
    root to: 'users#index'
    resources :users, only: %w(show index) do
      collection do
        post :search
      end
    end
  end

  namespace :analytic do
    root to: 'users#index'
    resources :users, only: %w(show index) do
      collection do
        post :search
      end
    end
  end


  post '/eshq/socket' =>  'push_to_web#socket'
  post '/push_to_web/graph_ready' =>  'push_to_web#graph_ready'

  root :to => 'facebook_profiles#login'


  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'

end
