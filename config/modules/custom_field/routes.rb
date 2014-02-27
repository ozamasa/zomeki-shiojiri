ZomekiCMS::Application.routes.draw do
  mod = 'custom_field'

  ## admin
  scope "#{ZomekiCMS::ADMIN_URL_PREFIX}/#{mod}", :module => mod, :as => mod do
    resources :content_base,
      :controller => 'admin/content/base'

    resources :content_settings, :only => [:index, :show, :edit, :update],
      :controller  => "admin/content/settings",
      :path        => ":content/content_settings"

    ## contents
    resources :forms,
      :controller  => "admin/forms",
      :path        => ":content/forms"

    resources :docs,
      :controller  => "admin/docs",
      :path        => ":content/docs" do
        collection do
          post :article
        end
      end

    resources :import, :only => [:index],
      :controller  => "admin/import",
      :path        => ":content/import" do
      collection do
        post :import
      end
    end
  end

end
