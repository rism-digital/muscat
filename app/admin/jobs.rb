#based on https://gist.github.com/webmat/1887148

ActiveAdmin.register Delayed::Job, as: 'Job' do
  menu :parent => "admin_menu", :label => proc {I18n.t(:menu_jobs)}, :if => proc{ can? :manage, Delayed::Job }

  actions :index, :show, :update, :destroy
  config.filters = false

  controller do
    def destroy
      @job = Delayed::Job.find(params[:id])
      if (!@job.failed_at && @job.locked_at)
        redirect_to admin_jobs_path, :flash => { :error => "Running jobs cannot be deleted" }
      else
        destroy!
      end
    end
  end

  index do
    column :id
    column ("Status") do |job| 
      if job.failed_at
        status_tag("Failed", :error, id: "job-banner-#{job.id}")
      else
        if !job.locked_at
          status_tag("Waiting", :no, id: "job-banner-#{job.id}")
        else
          status_tag("Running", :yes, id: "job-banner-#{job.id}")
        end
      end
    end
    column ("Progress") do |job|
      render(partial: "jobs/jobs_progress", locals: { job: job })
    end
    column ("%") do |job|
      percent = (job.progress_current.to_f / job.progress_max.to_f) * 100
      span(!percent.nan? ? percent.round(1) : "0%", id: "progress-percent-#{job.id}")
    end
    column :progress_stage do |job|
      span(job.progress_stage, id: "progress-status-#{job.id}")
    end
    column :object do |job|
      link_to("#{job.parent_type} #{job.parent_id}", )
      link_to "#{job.parent_type} #{job.parent_id}", controller: job.parent_type.pluralize.underscore.downcase.to_sym, action: :show, id: job.parent_id
    end
    column :queue
    column :failed_at
    column :run_at
    column :created_at
    actions
  end

end