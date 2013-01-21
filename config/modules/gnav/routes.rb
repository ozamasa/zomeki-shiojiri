ZomekiCMS::Application.routes.draw do
  mod = 'gnav'

  ## admin
  scope "#{ZomekiCMS::ADMIN_URL_PREFIX}/#{mod}", :module => mod, :as => mod do
    resources :content_base,
      :controller => 'admin/content/base'

    resources :content_settings, :only => [:index, :show, :edit, :update],
      :controller => 'admin/content/settings',
      :path       => ':content/content_settings'

    ## contents
    resources :menu_items,
      :controller => 'admin/menu_items',
      :path       => ':content/menu_items'
  end
end
