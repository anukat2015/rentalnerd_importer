class ImportJob < ActiveRecord::Base
  has_many :import_diffs, dependent: :destroy
  has_many :import_logs, dependent: :destroy

  after_commit :slack_it

  def slack_it
    SlackPinger.perform_async id
  end
end
