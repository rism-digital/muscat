ActiveAdmin.register_page "Statistic" do

  sidebar :search do
    form :class =>'filer_form' do |f|
      f.input :end_date, :class => 'datepicker hasDatePicker'
      f.button :submit, :class => 'buttons' 
    end
  end

  controller do
    def index
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
        @statistic = Statistic.new(@from_date, @to_date, User.where.not(:id => 1))
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


    panel "Table of users" do
      render :partial => 'statistics/user_table'
    end
    panel "Table of wokgroups" do
      render :partial => 'statistics/workgroup_table'
    end


  end
end
