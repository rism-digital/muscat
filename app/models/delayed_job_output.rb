class DelayedJobOutput < ApplicationRecord
  belongs_to :delayed_job, class_name: "Delayed::Job"

  validates :delayed_job_id, presence: true
end
