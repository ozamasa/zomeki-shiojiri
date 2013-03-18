ZomekiCMS::Application.routes.draw do
  mod = 'map'

  ## admin
  scope "#{ZomekiCMS::ADMIN_URL_PREFIX}/#{mod}", :module => mod, :as => mod do
    resources :content_base,
      :controller => 'admin/content/base'

    ## contents
    resources :markers,
      :controller => 'admin/markers',
      :path       => ':content/markers'

    ## nodes
    resources :node_markers,
      :controller => 'admin/node/markers',
      :path       => ':parent/node_markers'
  end
end
