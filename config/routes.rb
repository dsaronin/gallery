Rails.application.routes.draw do
  get 'folder/index'
  get 'folder/selectfolder'
  post 'folder/loadphotos'
  resources :folder, only: [:show, :destroy]
  resources :photo,  only: [:show, :edit, :update, :destroy]
  resources :talent
  resources :portfolio
  resources :category, only: [:create, :update, :destroy]
  resources :tag,      only: [:index, :create, :update, :destroy]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "folder#index"
end
