class PurgeSearchesJob < ApplicationJob
  queue_as :default
  
  def perform(*args)
    ap self
    Search.delete_old_searches(7)
  end
end
