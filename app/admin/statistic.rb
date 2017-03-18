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
      @statistic = Statistic.new(@from_date, @to_date, User.with_role(:cataloger))
    end
  end

  content do
    panel "Graph of workgroup #{}" do
      render :partial => 'statistics/chart'
    end

    panel "Table of users" do
      #render :partial => 'statistics/ut'
    end

    columns do 
      column do 
        panel "Table" do
          #render :partial => 'statistics/workgroup_table'
        end
      end
      column do
        panel "Most active workgroups #{}" do
          render :partial => 'statistics/pie'
        end
      end

    end
  end
end
