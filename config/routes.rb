Masha::Application.routes.draw do
  root 'welcome#index'

  get '/auth/:provider/callback', to: 'sessions#create'
  # TODO Добавить routes для отработки
  # http://masha.brandymint.ru/auth/failure?message=invalid_credentials&strategy=github
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
