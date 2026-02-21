Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Upload flow
  get "upload", to: "documents#new", as: :upload
  post "upload", to: "documents#create"

  # Results and collapsed views
  get "results/:id", to: "documents#results", as: :results
  post "collapsed/:id", to: "documents#select_version", as: :collapsed
  get "collapsed/:id", to: "documents#collapsed", as: :collapsed_show

  # Text-to-speech generation
  post "speech/:id", to: "documents#generate_speech", as: :generate_speech

  # Profile
  get "profile", to: "profiles#show", as: :profile

  # Defines the root path route ("/")
  root "pages#home"
end
