Rails.application.routes.draw do
  get 'catalog/index'
  get 'catalog/selectcatalog'
  get 'dashboard', to: 'dashboard#index'
  post 'catalog/loadphotos'
  resources :catalog, only: [:show, :update, :destroy]
  resources :photo,  only: [:show, :update] do
    member do
      post 'assign_tag'
      delete 'remove_tag/:tag_id', action: :remove_tag, as: :remove_tag
    end
  end

  resources :talent do
    member do
      patch :set_cover
    end
  end

  concern :curatable do
    resource :curation, only: [:show] do
      collection do
        post :preview
        post :commit
        delete :clear
      end
    end
  end

  resources :portfolio, controller: :portfolio, concerns: :curatable do
    member do
      delete :clear_items
    end
  end

  resources :exhibition, controller: :exhibition, concerns: :curatable do
    member do
      delete :clear_items
    end
  end

  resources :category, only: [:create, :update, :destroy]
  resources :tag,      only: [:index, :create, :update, :destroy]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "dashboard#index"
end
