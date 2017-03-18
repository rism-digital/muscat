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
      statistic = Workgroup.sources_by_range(@from_date, @to_date, Workgroup.all.limit(3))
      @result = Workgroup.sources_size_per_month(@from_date, @to_date, statistic)
      @wg = Workgroup.most_active_users(@from_date, @to_date, statistic)
    end
  end

  content do
    panel "Graph of workgroup #{}" do
      render :partial => 'statistics/chart'
    end

    panel "Table of users" do
      render :partial => 'statistics/user_table'
    end

    columns do 
      column do 
        panel "Table" do
          render :partial => 'statistics/table'
        end
      end
      column do
        panel "Most active users of workgroup #{}" do
          render :partial => 'statistics/pie'
        end
      end

    end
  end
end
