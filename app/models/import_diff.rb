class ImportDiff < ActiveRecord::Base
  class << self  
    def purge_records origin_urls
      ImportDiff.destroy_all( origin_url: origin_urls )
    end    
  end
end
