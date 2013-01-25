ZomekiCMS::Application.routes.draw do
  mod = "portal_calendar"
  
  ## admin
  scope "#{ZomekiCMS::ADMIN_URL_PREFIX}/#{mod}", :module => mod, :as => mod do
    resources :events,
      :controller  => "admin/events",
      :path        => ":content/events"
    
    ## content
    resources :content_base,
      :controller => "admin/content/base"
    resources :content_settings,
      :controller  => "admin/content/settings",
      :path        => ":content/content_settings"
    resources :statuses,
      :controller  => "admin/statuses",
      :path        => ":content/statuses"
    resources :genres,
      :controller  => "admin/genres",
      :path        => ":content/genres"
		
    ## node
    resources :node_events,
      :controller  => "admin/node/events",
      :path        => ":parent/node_events"
    resources :node_statuses,
      :controller  => "admin/node/statuses",
      :path        => ":parent/node_statuses"
    resources :node_genres,
      :controller  => "admin/node/genres",
      :path        => ":parent/node_genres"
    
    ## piece
    resources :piece_monthly_links,
      :controller  => "admin/piece/monthly_links"
    resources :piece_daily_links,
      :controller  => "admin/piece/daily_links"
  end
  
  ## public
  scope "_public/#{mod}", :module => mod, :as => "" do
    match "node_events/index"              => "public/node/events#index",
      :as => nil
    match "node_events/:year/index"        => "public/node/events#index_yearly",
      :as => nil
    match "node_events/:year/:month/index" => "public/node/events#index_monthly",
      :as => nil
  end
end
