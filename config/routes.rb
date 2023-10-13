Rails.application.routes.draw do
  get 'folder/index'
  get 'folder/selectfolder'
  post 'folder/loadphotos'
  resources :folder, only: [:show, :destroy]
  resources :photo,  only: [:show, :edit, :destroy]
  resources :talent
  resources :portfolio
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "folder#index"
end
