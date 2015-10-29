module PredictionResultsHelper
  def get_areas
    Neighborhood.select(:shapefile_source).distinct.pluck(:shapefile_source)
  end
end
