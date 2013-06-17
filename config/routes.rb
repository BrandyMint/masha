Masha::Application.routes.draw do
  root 'welcome#index'

  get '/auth/:provider/callback', to: 'sessions#create'
  post '/auth/:provider/callback', to: 'sessions#create'
  # TODO Добавить routes для отработки
  # http://masha.brandymint.ru/auth/failure?message=invalid_credentials&strategy=github
  delete "signout" => "sessions#destroy", :as => :signout

  # Личный контроллер пользователя
  resource :user, :controller => :user

  resources :projects do
    member do
      post :set_role
      delete :remove_role
    end
  end

  namespace :admin do
    root :controller => :users, :action => :index
    resources :projects
    resources :users
  end

  namespace :private do

  end

  resources :time_shifts

end
