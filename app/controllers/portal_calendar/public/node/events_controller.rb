# encoding: utf-8
class PortalCalendar::Public::Node::EventsController < Cms::Controller::Public::Base
  def pre_dispatch
    @node     = Page.current_node
    @node_uri = @node.public_uri
    return http_error(404) unless @content = @node.content
    
    @today    = Date.today
    @min_date = Date.new(@today.year, @today.month, 1) << 0
    @max_date = Date.new(@today.year, @today.month, 1) >> 11

		@genres = PortalCalendar::Event.get_genre_valid_list(@content.id)
		@statuses = PortalCalendar::Event.get_status_valid_list(@content.id)

		@max_row = 5
		@max_column = 7 - 1
		@base_nbr = 0
		
  end

	#要素を整数化した配列を返す
	def conv_to_i(h)
		h.map{|item| item.to_i}
	end
	
	def calendar
    params[:year]  = @today.strftime("%Y").to_s
    params[:month] = @today.strftime("%m").to_s

		return calendar_monthly
	end
	
	def prepare_monthly_data(uri_suffix="")
    return http_error(404) unless validate_date
    return http_error(404) if Date.new(@year, @month, 1) < @min_date
    return http_error(404) if Date.new(@year, @month, 1) > @max_date

		#前後の月の抽出条件を引き継ぐ
		_genres = params[:genres].nil? ? [] : params[:genres].split(",")
		_statuses = params[:statuses].nil? ? [] : params[:statuses].split(",")
		
		#フォームでsubmitされたときはフォームの抽出条件で処理する
		@genre_keys = params[:genre].nil? ? conv_to_i(_genres) : conv_to_i(params[:genre].keys)
		@status_keys = params[:status].nil? ? conv_to_i(_statuses) : conv_to_i(params[:status].keys)
    
    @sdate = "#{@year}-#{@month}-01"
    @edate = (Date.new(@year, @month, 1) >> 1).strftime('%Y-%m-%d')
    
    @calendar = Util::Date::Calendar.new(@year, @month)
    @calendar.month_uri = "#{@node_uri}:year/:month/" + uri_suffix
    
    @items = {}
    @calendar.days.each{|d| @items[d[:date]] = [] if d[:month].to_i == @month }

		events = PortalCalendar::Event.get_period_records_with_content_id(@content.id, @sdate, @edate)
		events = events.where("genre_id IN (?) AND status_id IN (?)", @genre_keys, @status_keys)
		
		events.each do |ev|
      (ev.event_start_date .. ev.event_end_date).each do |evdate|
				#その月のイベントか？
				# TODO: 要確認/元の資料のとおりの実装だが、これだとカレンダーに表示される前後の月の範囲のイベントを表示しない仕様。前後の月に移動するとイベントを表示するので違和感あり？
				next if evdate.month != @month

				@items[evdate.to_s] << ev
			end
    end

		condition_str = "genres=#{@genre_keys.join(",")}&statuses=#{@status_keys.join(",")}"
		
    @pagination = Util::Html::SimplePagination.new
    @pagination.prev_label = "&lt;前の月"
    @pagination.next_label = "次の月&gt;"
    @pagination.prev_uri   = @calendar.prev_month_uri + "?#{condition_str}" if @calendar.prev_month_date >= @min_date
    @pagination.next_uri   = @calendar.next_month_uri + "?#{condition_str}" if @calendar.next_month_date <= @max_date
	end
	
	def calendar_monthly

		prepare_monthly_data("calendar")

		#カレンダーの開始曜日
		@start_wday = 0
		first_date = Date.new(@year, @month, 1)
		#カレンダー先頭の日(カレンダーの先頭日はだいたい前の月なのでその調整）
		box_start_date = first_date - first_date.cwday  + @start_wday
		if box_start_date > first_date
			box_start_date = box_start_date - 7
		end
 		max_row = @max_row
		max_column = @max_column
		base_nbr = @base_nbr
		
		#表示のイメージのまま、その日のデータを詰めていく
		@box=[]
		base_nbr.upto(max_row) do |row|
			@box[row]=[]
			base_nbr.upto(max_column) do |coloumn|
				data = {:date => box_start_date + row*(max_column+1) + coloumn}
				#hashキーのフォーマットは yyyy-mm-dd
				data.merge!({:events => @items[data[:date].strftime('%Y-%m-%d')]})
				@box[row][coloumn] = data
			end
		end
		
		respond_to do |format|
			format.html {render :action => "index_calendar"}
		end

	end

  
  def index
    params[:year]  = @today.strftime("%Y").to_s
    params[:month] = @today.strftime("%m").to_s

    return index_monthly
  end
  
  def index_monthly

		prepare_monthly_data
		
		respond_to do |format|
			format.html {render :action => "index_monthly"}
		end
  end
 
 
protected
  def event_docs
    content_id = @content.setting_value(:doc_content_id)
    return [] if content_id.blank?
    
    doc = Article::Doc.new.public
    doc.agent_filter(request.mobile)
    doc.and :content_id, content_id
    doc.event_date_is(:year => @year, :month => @month)
    doc.find(:all, :order => 'event_date')
  end
  
  def validate_date
    @month = params[:month]
    @year  = params[:year]
    return false if !@month.blank? && @month !~ /^(0[1-9]|10|11|12)$/
    return false if !@year.blank? && @year !~ /^[1-9][0-9][0-9][0-9]$/
    @year  = @year.to_i
    @month = @month.to_i if @month
    params[:calendar_event_year]  = @year
    params[:calendar_event_month] = @month
    params[:calendar_event_min_date] = @min_date
    params[:calendar_event_max_date] = @max_date
    return true
  end
end