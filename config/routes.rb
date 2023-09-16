Rails.application.routes.draw do
  get 'photo/index'
  get 'photo/show'
  get 'folder/index'
  get 'folder/show'
  post 'folder/loadphotos'
  resources :talent
  resources :portfolio
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
