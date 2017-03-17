ActiveAdmin.register_page "Statistic" do

  sidebar :search do
    form :class =>'filer_form' do |f|
      f.input :end_date, :class => 'datepicker hasDatePicker'
      f.button :submit, :class => 'buttons' 
    end
  end

  controller do
    def index
      @result = Workgroup.all_sources_by_range(Time.now - 12.month, Time.now)
    end
  end

  content do

    panel "Graph" do
      render :partial => 'statistics/chart'
    end

    columns do 
      column do 
        panel "Table" do
          render :partial => 'statistics/table'
        end
      end
      column do
        panel "Pie" do
          render :partial => 'statistics/pie'
        end
      end


    end
  end
end
