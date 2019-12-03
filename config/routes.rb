Rails.application.routes.draw do
  resources Phrasing.route,
            as: :phrasing_phrases,
            controller: :phrasing_phrases,
            only: [:index, :edit, :update, :destroy] do
    collection do
      get  :help
      get  :import_export
      get :request_go_live
      get  :go_live_status
      get  :download
      post :upload
    end
  end

  resources :phrasing_phrase_versions, only: :destroy
end