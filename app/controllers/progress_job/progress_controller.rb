module ProgressJob
  class ProgressController < ApplicationController
    before_action :authenticate_user!

    def show
      job = Delayed::Job.find(params[:job_id])
      render json: progress_response(job)
    rescue ActiveRecord::RecordNotFound
      # Delayed Job deletes successful rows, so preserve the existing finished-job behavior.
      render json: empty_progress_response(status: "complete", percentage: 100)
    end

    private

    def progress_response(job)
      maximum = job.progress_max.to_i
      current = job.progress_current
      percentage = if current.nil? || current.negative?
        nil
      elsif maximum.positive?
        (current / maximum.to_f * 100).clamp(0, 100)
      else
        0
      end

      status = if job.failed_at.present?
        "failed"
      elsif job.locked_at.present?
        "running"
      else
        "queued"
      end

      {
        status: status,
        progress_stage: job.progress_stage,
        progress_current: current,
        progress_max: maximum,
        percentage: percentage
      }
    end

    def empty_progress_response(status:, percentage:)
      {
        status: status,
        progress_stage: nil,
        progress_current: nil,
        progress_max: nil,
        percentage: percentage
      }
    end
  end
end
