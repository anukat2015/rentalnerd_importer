class ImportJob < ActiveRecord::Base
  has_many :import_diffs, dependent: :destroy
  has_many :import_logs, dependent: :destroy
end
