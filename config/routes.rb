# frozen_string_literal: true

require 'admin_constraint'

Masha::Application.routes.draw do
  default_url_options ApplicationConfig.default_url_options.symbolize_keys
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if defined? LetterOpenerWeb
  get 'up' => 'rails/health#show', as: :rails_health_check

  root 'welcome#index'

  get 'auth/:provider/callback', to: 'omniauth_session#create'
  post 'auth/:provider/callback', to: 'omniauth_session#create'
  # TODO: Добавить routes для отработки
  # http://masha.brandymint.ru/auth/failure?message=invalid_credentials&strategy=github

  get 'logout' => 'sessions#destroy', :as => 'logout'
  get 'login' => 'sessions#new', :as => 'login'
  get 'signup' => 'users#new', :as => 'signup'
  get 'feedback' => 'pages#feedback', :as => 'feedback'
  get 'noaccess' => 'pages#noaccess', :as => 'noaccess'
  get 'support' => redirect('/feedback')
  get 'error' => 'errors#index', :as => 'error'

  resources :users, only: %i[new create]
  resources :sessions, only: %i[new create destroy]

  get 'ta/:id', action: :create, controller: 'telegram/attach', as: :attach_telegram

  get 'telegram/auth_callback', to: 'telegram_auth_callback#create'
  get 'telegram/confirm', to: 'telegram_auth_callback#confirm'
  if Rails.env.test?
  # В тестовой среде определяем роуты вручную для integration тестов
  post '/telegram/:token', to: 'telegram/webhook#create', defaults: { format: :json }
else
  telegram_webhook Telegram::WebhookController
end

  constraints subdomain: 'admin' do
    constraints AdminConstraint do
      mount SolidQueueDashboard::Engine, at: '/solid-queue'
    end
  end

  # Личный контроллер пользователя
  resource :profile, controller: :profile do
    collection do
      post :change_password
    end
  end

  resources :password_resets, only: %i[new create edit update]

  resources :projects do
    resources :memberships
    member do
      put :activate
      put :archivate
    end
  end
  resources :time_shifts do
    collection do
      get :summary
    end
  end
  resources :invites, only: %i[create destroy]

  namespace :owner do
    root controller: :users, action: :index
    resources :projects do
      resources :memberships

      member do
        post :set_role
        delete :remove_role
      end
    end
    resources :users
  end

  resources :users
end
