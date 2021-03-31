Rails.application.routes.draw do

  namespace :api do
    namespace :v1 do
      post '/responses/emails', to: 'responses#emails'
      resources :surveys, only: [:index, :new, :create, :show, :destroy] do
        resources :choices, only: [:new, :create]
        resources :responses, only: [:index, :new, :create, :show, :update] do
          resources :rankings, only: [:new, :create, :update]

        end
      end
      resources :responses, only: [:index, :new, :create, :destroy] do
        resources :rankings, only: [:new, :create]
      end
      resources :choices, only: [:update, :destroy] do
        resources :rankings, only: [:destroy]
      end
      resources :rankings, only: [:update]
    end
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
