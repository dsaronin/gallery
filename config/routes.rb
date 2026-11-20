Rails.application.routes.draw do
# *********************************************

  get 'dashboard', to: 'dashboard#index'
  get 'dashboard/branding', to: 'dashboard#branding'

# *********************************************
  concern :gang_taggable do
    member do
      post :assign_tag
    end
  end

# *********************************************
  get 'catalog/index'
  get 'catalog/selectcatalog'
  post 'catalog/loadphotos'
  resources :catalog, only: [:show, :update, :destroy], concerns: :gang_taggable

# *********************************************
  resources :photo,  only: [:show, :update] do
    member do
      post   'assign_tag'
      delete 'remove_tag/:tag_id', action: :remove_tag, as: :remove_tag
      post   'assign_portfolio'
      delete 'remove_portfolio/:portfolio_id', action: :remove_portfolio, as: :remove_portfolio
      post   'assign_exhibition'
      delete 'remove_exhibition/:exhibition_id', action: :remove_exhibition, as: :remove_exhibition
    end
  end

# *********************************************
  resources :talent do
    member do
      patch :set_cover
    end
  end

# *********************************************
  concern :curatable do
    resource :curation, only: [:show] do
      collection do
        post :preview
        post :commit
        delete :clear
      end
    end
  end

# *********************************************
  concern :shareable do
    member do
      patch :make_public
      patch :make_private
    end
  end

# *********************************************
  resources :portfolio, controller: :portfolio, concerns: [:curatable, :gang_taggable, :shareable] do
    member do
      delete :clear_items
      patch  :move_item
    end
  end

# *********************************************
  resources :exhibition, controller: :exhibition, concerns: [:curatable, :gang_taggable, :shareable] do
    member do
      delete :clear_items
      patch  :move_item
      get    :download_placards
    end
  end

# *********************************************
  resources :venue, controller: :venue
  resources :showing, controller: :showing

# *********************************************
  resources :placard, controller: :placard do
    collection do
      get :collection_show, action: :show
      get :itemcard
      get :display
    end
    member do
      get :itemcard
      get :display
    end
  end

# *********************************************
  resources :category, only: [:create, :update, :destroy]
  resources :tag,      only: [:index, :create, :update, :destroy]

# *********************************************
  resources :public_access, controller: :public_access, only: [:index, :new, :create, :edit, :update] do
    member do
      patch :revoke
    end
  end

# *********************************************
  # Serve local/NFS photo repository in memory during development or standalone production tests.
  # In production behind Nginx, RAILS_SERVE_STATIC_FILES is unset and Nginx serves /photos/ directly.
# *********************************************
  if Rails.env.development? || ENV["RAILS_SERVE_STATIC_FILES"].present?
    mount Rack::Files.new(Gallery::Environ.instance.target_pictures_path), at: "/photos"
  end

# *********************************************
# *********************************************
  # Defines the root path route ("/")
# *********************************************
  root "dashboard#index"
# *********************************************
end
