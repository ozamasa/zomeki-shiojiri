ZomekiCMS::Application.routes.draw do
  mod = 'sns_share'

  ## admin
  scope "#{ZomekiCMS::ADMIN_URL_PREFIX}/#{mod}", :module => mod, :as => mod do
    resources :content_base,
      :controller => 'admin/content/base'
  end
end
