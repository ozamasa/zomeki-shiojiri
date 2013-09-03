# encoding: utf-8
class Cms::Admin::Tool::LinkCheckController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:designer)
  end

  def index
    link_check = Util::LinkChecker.check_in_progress

    if request.post?
      unless link_check
#TODO: Consider to execute check
        Thread.fork {
          Util::LinkChecker.check
        }
        sleep 3
      end

      redirect_to tool_link_check_url
    else
      @logs = (if link_check
                current = link_check.logs.where(checked: true).count
                total = link_check.logs.count
                flash[:notice] = "リンクチェックを実行中です。(#{current}/#{total}件)"
                @reload = true
                link_check.logs
              else
                Util::LinkChecker.last_check.try(:logs) || Cms::LinkCheckLog.none
              end).where(checked: true, result: false)
    end
  end
end
