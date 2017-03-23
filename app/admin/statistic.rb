ActiveAdmin.register_page "Statistic" do

  # FIXME right management
  menu :parent => "admin_menu", :label => "Statistics"

  sidebar :info do
    h4 do
      "This page contains statistical information."
    end
    #form :class =>'filer_form' do |f|
    #  f.input :end_date, :class => 'datepicker hasDatePicker'
    #  f.button :submit, :class => 'buttons' 
    #end
  end

  controller do
    def index
      ActiveAdmin.setup do |config|
        config.register_stylesheet "#{Rails.root}/app/assets/stylesheets/tabs.css"
      end
      @from_date, @to_date = Time.now - 12.month, Time.now
      if params['workgroup']
        @att = :name
        @workgroup = Workgroup.where(:name => params['workgroup']).take
        @statistic = Statistic.new(@from_date, @to_date, @workgroup.users)
      elsif params['user']
        @att = :name
        @statistic = Statistic.new(@from_date, @to_date, User.where(:id => params['user']))
      else
        @att = :workgroup
        users = User.where.not(:id => 1).joins(:workgroups).order('workgroups.name', :name)
        #users = User.where(:id => 28)
        stats = Statistic::User.sources_by_month((Time.now-1.year).beginning_of_month, Time.now, users)
        @statistic = Statistic::Factory.new(stats)
      end
    end
  end

  content do
    columns do 
      column do 
        panel "Chart", style: "width: 800px; margin-bottom: 20px" do
          render :partial => 'statistics/chart'
        end
      end
      column do
        panel "Most active", style: "margin-left: auto; width: 350px" do
          render :partial => 'statistics/workgroups_pie'
        end
      end
    end

    div do
      tabs do
        tab "User table" do
          render :partial => 'statistics/user_table'
        end
        tab "Workgroup table" do
          render :partial => 'statistics/workgroup_table'
        end
      end
    end
   end

end
