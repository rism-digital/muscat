class RegenerateWorkgroupInstitutionLinksJob < ApplicationJob
  queue_as :default

  def perform
    Workgroup.find_each(&:change_institutions)
  end
end
