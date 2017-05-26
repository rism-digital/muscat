ActiveAdmin.register_page "Statistics" do

  # FIXME right management
  menu :parent => "admin_menu", :label => "Statistics"
  
  page_action :index, :method => :post do
      redirect_to :action => :index
  end
  
  sidebar :search do
    active_admin_form_for :search, :url => admin_statistics_index_path do |f|
      f.input :from_date, :label => "From:", :as => :datepicker, :input_html => {:style => 'width: 90%' }
      f.input :to_date, :label => "To:", :as => :datepicker, :input_html => {:style => 'width: 90%' }
      div do
        f.input :workgroup, :label => "Workgroup", :as => :select, :collection => Workgroup.order(:name), :input_html => {:style => 'width: 90%'}, :prompt => 'All'
      end
      f.actions
    end
  end
  
  controller do
    def index
      if params['search'] && !(params['search']['from_date']).blank?
        @from_date = (Time.parse(params['search']['from_date']).localtime)
      else
        @from_date = (Time.now-12.month).beginning_of_month
      end
      if params['search'] && !(params['search']['to_date']).blank?
        @to_date = (Time.parse(params['search']['to_date']).localtime)
      else
        @to_date = Time.now        
      end
      if params['search'] && !(params['search']['workgroup']).blank?
        @workgroup = params['search']['workgroup']
      else
        @workgroup = nil
      end
      if !@workgroup
        @att = :workgroup
        users = User.where.not(:id => 1).joins(:workgroups).order('workgroups.name', :name)
      else
        @att = :name
        users = User.where.not(:id => 1).joins(:workgroups).where('workgroups.id' => @workgroup).order('workgroups.name', :name)
      end
      stats = Statistics::User.sources_by_month(@from_date.beginning_of_month, @to_date, users)
      @statistic = Statistics::Spreadsheet.new(stats)
    end
  end

  content do
    columns do 
      column do 
        panel "Chart", style: "width: 130%; margin-bottom: 20px" do
          render :partial => 'statistics/chart'
        end
      end
      column do
        panel "Most active", style: "margin-left: auto; width: 60%" do
           render :partial => 'statistics/workgroups_pie'
        end
      end
    end

    div do
      tabs do
        tab "User table" do
          render :partial => 'statistics/user_table'
        end
        unless workgroup
          tab "Workgroup table" do
            render :partial => 'statistics/workgroup_table', :locals => {:from_date => from_date, :to_date => to_date }
          end
        end
      end
    end

   div do
     tabs do
       tab "Sigla" do
          render :partial => 'statistics/sigla_pie'
       end
       tab "Overall Publishing/Unpublishing" do
          render :partial => 'statistics/status_bar'
       end
     end
   end
  end
end
