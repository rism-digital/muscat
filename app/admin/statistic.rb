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
      @workgroup = Workgroup.find(1)
      @result = @workgroup.sources_size_per_month(@from_date, @to_date)
      @wg = @workgroup.most_active_users(@from_date, @to_date)
    end
  end

  content do
    panel "Graph of workgroup #{workgroup.name}" do
      render :partial => 'statistics/chart'
    end

    columns do 
      column do 
        panel "Table" do
          render :partial => 'statistics/table'
        end
      end
      column do
        panel "Most active users of workgroup #{workgroup.name}" do
          render :partial => 'statistics/pie'
        end
      end

    end
  end
end
