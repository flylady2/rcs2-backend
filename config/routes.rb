Rails.application.routes.draw do

  namespace :api do
    namespace :v1 do
      post '/surveys/trigger', to: 'surveys#trigger'

      post '/responses/emails', to: 'responses#emails'

      resources :surveys, only: [:index, :new, :create, :destroy] do
        resources :choices, only: [:new, :create]
        resources :responses, only: [:new, :create] 
          #resources :rankings, only: [:new, :create, :update]

        #end
      end
      resources :responses, only: [:new, :create, :destroy] do
        resources :rankings, only: [:new, :create, :update]
      end
      resources :choices, only: [:destroy] #do
        #resources :rankings, only: [:destroy]
      #end
      #resources :rankings, only: [:update]
    end
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
