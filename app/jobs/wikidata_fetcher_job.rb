class WikidataFetcherJob < ProgressJob::Base

  def initialize(qid)
    @qid = qid
  end

  def perform
    update_progress_max(100)
    update_stage_progress("Fetching #{@qid} from Wikidata", step: 10)

    begin
      output = Wikidata::Connector.get_person(@qid)
      status = "ok"
    rescue Wikidata::Connector::RecordInRISM => e
      output = e.message
      status = "RecordInRISM"
    end
    
    update_stage_progress('Data fetched', step: 80)

    DelayedJobOutput.create!(
      delayed_job_id: @job.id,
      output: output,
      status: status
    )
    
    # 'succeeded' signals the backed it can go on
    update_stage_progress('succeeded', step: 10)

    # Give time to the fronted to stop
    sleep(5)
  end
  
  def destroy_failed_jobs?
    false
  end
  
  def max_attempts
    1
  end
  
  def queue_name
    'reindex'
  end

end