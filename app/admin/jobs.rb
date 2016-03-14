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
          status_tag("Running", :ok, id: "job-banner-#{job.id}")
        end
      end
    end
    column ("Progress") do |job|
      render(partial: "jobs/jobs_progress", locals: { job: job })
    end
    column :progress_stage do |job|
      span(job.progress_stage, id: "progress-status-#{job.id}")
    end
    column :queue
    column :failed_at
    column :run_at
    column :created_at
    actions
  end

  action_item :only => [:edit] do
    link_to 'Delete Job', admin_job_path(resource),
            'data-method' => :delete, 'data-confirm' => 'Are you sure?'
  end

  action_item :only => [:show, :edit] do
    link_to 'Schedule now', run_now_admin_job_path(resource), 'data-method' => :post,
      :title => 'Cause a job scheduled in the future to run now.'
  end

  action_item :only => [:show, :edit] do
    link_to 'Reset Job', reset_admin_job_path(resource), 'data-method' => :post,
      :title => 'Resets the state caused by errors. Lets a worker give it another go ASAP.'
  end

  member_action :run_now, :method => :post do
    resource.update_attributes run_at: Time.now
    redirect_to action: :index
  end

  member_action :reset, :method => :post do
    resource.update_attributes locked_at: nil, locked_by: nil, attempts: 0, last_error: nil
    resource.update_attribute :attempts, 0
    redirect_to action: :index
  end

end