require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  mount Sidekiq::Web => '/sidekiq'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :tasks, only: %i[index show create update destroy] do
        resources :tags, only: %i[create destroy], controller: 'task_tags'
      end
      resources :tags, only: %i[index show create update destroy]
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
