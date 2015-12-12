module PredictionResultsHelper
  def get_areas
    Neighborhood.select(:shapefile_source).distinct.pluck(:shapefile_source)
  end

  def get_transaction_type
    ["rental", "sales"]
  end  
end
