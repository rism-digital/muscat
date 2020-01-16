#based on https://gist.github.com/webmat/1887148

ActiveAdmin.register Delayed::Job, as: 'Job' do
  menu :parent => "admin_menu", :label => proc {I18n.t(:menu_jobs)}, :if => proc{ can? :manage, Delayed::Job }

  actions :index, :show, :update, :destroy
  
  # Remove all action items
  config.clear_action_items!
  
  config.filters = false

  controller do
    def destroy
      begin
        @job = Delayed::Job.find(params[:id])
        if (!@job.failed_at && @job.locked_at)
          redirect_to admin_jobs_path, :flash => { :error => I18n.t("jobs.running_jobs") }
        else
          destroy!
        end
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_jobs_path, :flash => { :warning => I18n.t("jobs.auto_delete") }
      end
    end
    
    def show
      begin
        show!
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_jobs_path, :flash => { :warning => I18n.t("jobs.no_view") }
      end
    end
    
  end
  
  ###########
  ## Index ##
  ###########

  index do
    column :id
    column I18n.t(:status) do |job| 
      if job.failed_at
        status_tag(I18n.t(:failed), :error, id: "job-banner-#{job.id}")
      else
        if !job.locked_at
          status_tag(I18n.t(:waiting), :no, id: "job-banner-#{job.id}")
        else
          status_tag(I18n.t(:running), :yes, id: "job-banner-#{job.id}")
        end
      end
    end
    column I18n.t(:progress) do |job|
      render(partial: "jobs/jobs_progress", locals: { job: job })
    end
    column ("%") do |job|
      percent = (job.progress_current.to_f / job.progress_max.to_f) * 100
      span(!percent.nan? ? percent.round(1) : "0%", id: "progress-percent-#{job.id}")
    end
    column I18n.t(:progress_stage) do |job|
      span(job.progress_stage, id: "progress-status-#{job.id}")
    end
    column I18n.t(:object) do |job|
      if job.parent_id
        link_to "#{job.parent_type} #{job.parent_id}", controller: job.parent_type.pluralize.underscore.downcase.to_sym, action: :show, id: job.parent_id
      else
        "No Object ID"
      end
    end
    column I18n.t(:queue), :queue
    column I18n.t(:failed_at), :failed_at
    column I18n.t(:run_at), :run_at
    column I18n.t(:created_at), :created_at
    actions
  end
  
  sidebar :actions, :only => :index do
    render :partial => "activeadmin/filter_workaround"
    render :partial => "activeadmin/section_sidebar_index"
  end
  
  ##########
  ## Show ##
  ##########
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => job }
  end

end