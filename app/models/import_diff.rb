class ImportDiff < ActiveRecord::Base
  class << self  
    def purge_records origin_url
      ImportDiff.destroy_all( origin_url: origin_url )
    end    
  end
end
