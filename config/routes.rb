Masha::Application.routes.draw do
  root 'welcome#index'

  post '/auth/:provider/callback', to: 'sessions#create'
  delete "signout" => "sessions#destroy", :as => :signout

  resources :projects do
    member do
      post :set_role
      delete :remove_role
    end
  end

  resources :users
  resources :time_shifts

end
