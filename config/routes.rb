Rails.application.routes.draw do
  # API endpoints (browser extension + web reader)
  namespace :api do
    post "web_reader", to: "web_reader#create"
    namespace :v1 do
      post "transform", to: "transformations#create"
      post "tts", to: "tts#create"
      post "summarize", to: "summaries#create"
      post "chat", to: "chat#create"
      get "profile", to: "profiles#show"
      patch "profile", to: "profiles#update"
      post "interactions", to: "interactions#create"
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

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
  post "profile/assessment", to: "profiles#assessment", as: :profile_assessment
  patch "profile/readability", to: "profiles#readability", as: :profile_readability

  # Billing & usage dashboard
  get "billing", to: "billing#show", as: :billing

  root "pages#home"
end
