class WikidataFetcherJob < ProgressJob::Base

  def initialize(qid)
    @qid = qid
  end

  def perform
    message = 'succeeded'
    update_progress_max(100)
    update_stage_progress("Fetching #{@qid} from Wikidata", step: 10)

    begin
      output = Wikidata::Connector.get_person(@qid)
      status = "ok"
    rescue Wikidata::Connector::RecordInRISM,
          Wikidata::Client::InvalidQid,
          Wikidata::Client::ConnectionError,
          Wikidata::Client::ItemNotFound => e

      output = e.message
      status = e.class.name.demodulize
      message = 'error'
    end
    
    update_stage_progress('Data fetched', step: 80)

    # Delete the old ones too
    DelayedJobOutput.where("created_at < ?", 6.hours.ago).delete_all

    DelayedJobOutput.create!(
      delayed_job_id: @job.id,
      output: output,
      status: status
    )
    
    # 'succeeded' signals the backed it can go on
    update_stage_progress(message, step: 10)

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