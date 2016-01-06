class ImportLog < ActiveRecord::Base
  class << self
    def get_import_batch_dates(source)
      self.where(source: source).distinct(:import_batch).order('import_batch DESC').pluck(:import_batch)
    end

    def purge_records origin_urls
      ImportLog.destroy_all( origin_url: origin_urls )
    end
  end
end
