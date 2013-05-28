Masha::Application.routes.draw do
  root 'welcome#index'

  resources :projects
  resources :users
  resources :time_shifts

  post '/auth/:provider/callback', to: 'sessions#create'
  delete "/signout" => "sessions#destroy", :as => :signout

end
