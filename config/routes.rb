Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :transfers, only: [:create, :show]

      namespace :webhooks do
        resources :transfers, only: [] do
          collection do
            post :transfer_result
          end
        end
      end
    end
  end
end
