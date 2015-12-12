class PredictionResultsController < ApplicationController

  def cap_ratios
    @area = params["area"] || "SF"
    @prediction_results = PredictionResult.prediction_results_by_cap_ratio @area
  end

  def outliers
    @area = params["area"] || "SF"
    @transaction_type = params["transaction_type"] || "rental"
    @prediction_results = PredictionResult.outliers @area, @transaction_type
  end  
end