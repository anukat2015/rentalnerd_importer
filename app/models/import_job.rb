class ImportJob < ActiveRecord::Base
  has_many :import_diffs, dependent: :destroy
  has_many :import_logs, dependent: :destroy

  after_commit :slack_it

  NORMALITY_THRESHOLD = 0.25

  def slack_it
    SlackPinger.perform_async id
  end

  def is_abnormal?
    abnormal
  end

  def get_previous_job_id
    return @previous_import_job_id unless @previous_import_job_id.nil?
    if task_key.present?
      @previous_import_job_id = ImportJob.where( source: source, task_key: task_key )
        .where( "id < ?", id ).order(id: :desc).limit(1).pluck(:id).first
    else
      @previous_import_job_id = ImportJob.where( source: source )
        .where( "id < ?", id ).order(id: :desc).limit(1).pluck(:id).first
    end    
  end

  def get_previous_job
    return @previous_import_job unless @previous_import_job.nil?

    if task_key.present?
      @previous_import_job = ImportJob.where( source: source, task_key: task_key )
        .where( "id < ?", id ).order(id: :desc).limit(1).first      
    else
      @previous_import_job = ImportJob.where( source: source )
        .where( "id < ?", id ).order(id: :desc).limit(1).first
    end    
  end

  def set_normalcy!
    if get_previous_job_id.nil? && removed_rows > 0
      update( abnormal: true )

    elsif 1.0 * removed_rows / get_previous_job.total_rows > NORMALITY_THRESHOLD
      update( abnormal: true )

    elsif 1.0 * removed_rows / get_previous_job.total_rows < NORMALITY_THRESHOLD
      update( abnormal: false )

    else
      raise "unknown normalcy level occurred"

    end    
  end
end
