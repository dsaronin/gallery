Rails.application.routes.draw do
  get 'portfolio/index'
  get 'portfolio/create'
  get 'portfolio/new'
  get 'portfolio/show'
  get 'portfolio/update'
  get 'portfolio/edit'
  get 'portfolio/destroy'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
