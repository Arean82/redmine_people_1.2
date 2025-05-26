
resources :people do
  collection do
    get :bulk_edit, :context_menu, :edit_mails, :preview_email, :avatar
    get :autocomplete_for_person
    post :bulk_edit, :bulk_update, :send_mails, :add_manager
    delete :bulk_destroy
    get 'calendar' => 'people_calendars#index'
    resources :holidays, except: :show, controller: :people_holidays, as: :people_holidays
  end

  member do
    get :manager
    get :autocomplete_for_manager
    delete :destroy_avatar
    get 'tabs/:tab' => 'people#show', :as => 'tabs'
    get 'load_tab' => 'people#load_tab', :as => 'load_tab'
    delete 'remove_subordinate' => 'people#remove_subordinate', :as => 'remove_subordinate'
  end
end

resources :departments do
  member do
    get :autocomplete_for_person
    post :add_people
    delete :remove_person
    get 'tabs/:tab' => 'departments#show', :as => 'tabs'
    get 'load_tab' => 'departments#load_tab', :as => 'load_tab'
  end

  get :org_chart, on: :collection
end

resources :people_settings do
  collection do
    get :autocomplete_for_user
  end
end

resources :people_queries, except: [:index]

constraints object_type: /(departments)/ do
  get 'attachments/:object_type/:object_id/edit', to: 'attachments#edit_all', as: 'departments_attachments_edit'
  patch 'attachments/:object_type/:object_id', to: 'attachments#update_all', as: 'departments_attachments'
  get 'attachments/:object_type/:object_id/download', to: 'attachments#download_all', as: 'departments_attachments_download'
end
