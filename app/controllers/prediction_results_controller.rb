class PredictionResultsController < ApplicationController

  def cap_ratios
    @area = params["area"] || "SF"
    @prediction_results = PredictionResult.prediction_results_by_cap_ratio @area
  end  
end