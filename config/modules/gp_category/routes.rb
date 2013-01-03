ZomekiCMS::Application.routes.draw do
  mod = 'gp_category'

  ## admin
  scope "#{ZomekiCMS::ADMIN_URL_PREFIX}/#{mod}", :module => mod, :as => mod do
    resources :content_base,
      :controller => 'admin/content/base'

    ## contents
    resources(:category_types,
      :controller => 'admin/category_types',
      :path       => ':content/category_types') do
      resources(:categories,
        :controller => 'admin/categories') do
        resources :categories,
          :controller => 'admin/categories'
      end
    end

    ## nodes
    resources :node_category_types,
      :controller => 'admin/node/category_types',
      :path       => ':parent/node_category_types'

    ## pieces
    resources :piece_category_types,
      :controller => 'admin/piece/category_types'
  end

  ## public
  scope "_public/#{mod}", :module => mod, :as => '' do
    match 'node_category_types(/index.:format)' => 'public/node/category_types#index'
    match 'node_category_types/:name(/index.:format)' => 'public/node/category_types#show'
    match 'node_category_types/:category_type_name/*category_names/index(.:format)' => 'public/node/categories#show'
    match 'node_category_types/:category_type_name/*category_names' => 'public/node/categories#show'
  end
end
