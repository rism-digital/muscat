module ProgressJob
  class ProgressController < ApplicationController
    before_action :authenticate_user!

    def show
      #return head :forbidden unless Ability.new(current_user).can?(:manage, Delayed::Job)

      job = Delayed::Job.find(params[:job_id])
      percentage = if job.progress_max.to_i.positive? && job.progress_current
        job.progress_current / job.progress_max.to_f * 100
      else
        0
      end

      render json: {
        progress_stage: job.progress_stage,
        progress_current: job.progress_current,
        progress_max: job.progress_max,
        percentage: percentage,
        last_error: job.last_error.present? ? true : nil
      }
    rescue ActiveRecord::RecordNotFound
      # Delayed Job removes completed jobs; the existing progress bar expects this value.
      render json: "none".to_json
    end
  end
end
