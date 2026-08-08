Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  scope "(:locale)", locale: /pl|en|ua/ do
    root "loan_comparisons#index"
    post "custom_compare", to: "loan_comparisons#custom_compare"
  end

  namespace :admin do
    root "dashboard#index"
    resources :banks
    resources :loan_offers do
      resources :loan_offer_changes, only: :index
    end
    resources :wibor_snapshots, only: :index do
      post :refresh, on: :collection
    end
  end
end
