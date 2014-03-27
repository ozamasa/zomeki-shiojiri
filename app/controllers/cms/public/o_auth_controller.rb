require 'net/https'

class Cms::Public::OAuthController < ApplicationController
  include Cms::Lib::OAuth

  def dummy
    warn_log 'Cms::Public::OAuthController#dummy should be intercepted by OmniAuth.'
    redirect_to request.base_url
  end

  def callback
    oa_params = request.env['omniauth.params']
    oa_auth = request.env['omniauth.auth']

    case oa_auth[:provider]
    when 'facebook'
      auth = {provider:              oa_auth['provider'],
              uid:                   oa_auth['uid'],
              info_nickname:         oa_auth['info']['nickname'],
              info_name:             oa_auth['info']['name'],
              info_image:            oa_auth['info']['image'],
              info_url:              oa_auth['info']['urls'].try('[]', 'Facebook').to_s,
              credential_token:      oa_auth.credentials.token,
              credential_expires_at: oa_auth.credentials.expires_at}

      session[:info_name] = auth[:info_name]
      session[:info_url]  = auth[:info_url]

      begin
        query = CGI.escape('SELECT name FROM profile WHERE id = me()')
        path = "/method/fql.query?format=JSON&access_token=#{auth[:credential_token]}&query=#{query}"
        https = Net::HTTP.new('api.facebook.com', 443)
        https.use_ssl = true
        auth[:info_name] = JSON.parse(https.get(path).body).first['name'].to_s
      rescue => e
        warn_log "Failed to get localized user name: #{e.message}"
      end

#TODO: extend token expiration
#      begin
#        apps = YAML.load_file(Rails.root.join('config/initializers/omniauth_facebook_apps.yml'))
#        if (app = apps[request.host])
#          path = "/oauth/access_token?client_id=#{app['id']}&client_secret=#{app['secret']}&grant_type=fb_exchange_token&fb_exchange_token=#{auth[:credential_token]}"
#          https = Net::HTTP.new('graph.facebook.com', 443)
#          https.use_ssl = true
#          new_token = CGI.parse(https.get(path).body)
#
#          info_log 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
#          info_log auth[:credential_token]
#          info_log new_token['access_token'].first.to_s
#          info_log 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
#          info_log auth[:credential_expires_at]
#          info_log new_token['expires'].first.to_s
#          info_log 'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'
#        end
#      rescue => e
#        warn_log "Failed to extend expires_at: #{e.message}"
#      end

      if oa_params.empty?
        user = Cms::OAuthUser.create_or_update_with_omniauth(auth)

        o_auth_session[:user_id] = user.id

        return_to = o_auth_session[:return_to]
        o_auth_session[:return_to] = nil

        return redirect_to(return_to || request.base_url)
      else
        if oa_params['class'].present? && oa_params['id'].present? && oa_params['return_to'].present?
          item = oa_params['class'].constantize.find(oa_params['id'])
          begin
            fb = RC::Facebook.new(access_token: auth[:credential_token])
            if fb.authorized?
              res = fb.get('me/accounts')
              options = [['自分のタイムライン', 'me']]
              if res.kind_of?(Hash) && (data = res['data']).kind_of?(Array)
                options.concat data.map{|d| ["ページ：#{d['name']}", d['id']] }
                auth[:facebook_page_options] = options
              end
              auth[:facebook_page] = 'me'
            end
          rescue => e
            warn_log "Failed to get pages to post: #{e.message}"
          end
          item.update_attributes(auth)

          return redirect_to(oa_params['return_to'])
        else
          return redirect_to(back_to(request.env['omniauth.origin']) || request.base_url)
        end
      end
    when 'twitter'
      auth = {provider:          oa_auth['provider'],
              uid:               oa_auth['uid'],
              info_nickname:     oa_auth['info']['nickname'],
              info_name:         oa_auth['info']['name'],
              info_image:        oa_auth['info']['image'],
              info_url:          oa_auth['info']['urls'].try('[]', 'Twitter').to_s,
              credential_token:  oa_auth.credentials.token,
              credential_secret: oa_auth.credentials.secret}

      if oa_params.empty?
        return redirect_to(request.base_url)
      else
        if oa_params['class'].present? && oa_params['id'].present? && oa_params['return_to'].present?
          item = oa_params['class'].constantize.find(oa_params['id'])

          item.update_attributes(auth)

          return redirect_to(oa_params['return_to'])
        else
          return redirect_to(request.base_url)
        end
      end
    else
      warn_log "Unknown provider: #{auth[:provider]}"
    end
  end

  def destroy
    session[:info_name] = nil
    session[:info_url]  = nil
    return redirect_to(back_to(params['origin']) || request.base_url)
  end

  def failure
    warn_log params.inspect
    redirect_to request.base_url
  end

private
  def back_to(origin)
    if origin.presence && back_to = CGI.unescape(origin.to_s)
      uri = URI.parse(back_to)
      return back_to if uri.relative? || uri.host == request.host
    end
  rescue
    nil
  end
end
