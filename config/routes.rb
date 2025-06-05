Rails.application.routes.draw do
  resources :subtask_templates do
    member do
      post :apply_to_issue
    end
  end
end
