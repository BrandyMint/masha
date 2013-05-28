Masha::Application.routes.draw do
  root 'welcome#index'

  post '/auth/:provider/callback', to: 'sessions#create'
  delete "/signout" => "sessions#destroy", :as => :signout

  resources :projects
  resources :users do
    member do
      post :add_role
      delete :remove_role
    end
  end
  resources :time_shifts

end
