class PredictionNeighborhood < ActiveRecord::Base
  belongs_to :prediction_model
  belongs_to :neighborhood

  class << self
    def import_prediction_neighborhoods! prediction_model_id, neighborhood_coeffi_file

      # For each neighborhood coefficient
      CSV.new( open( neighborhood_coeffi_file ), :headers => :first_row ).each do |row|
        puts "\n\timporting neighborhood_predictions for: #{row['neighborhood']}"
        curr_name = row["neighborhood"]

        # For each matching neighborhood in our database
        #   for neighborhoods that have multiple areas
        has_matching = false
        Neighborhood.where( "name LIKE ?", "%#{curr_name}%" ).each do |nb|
          has_matching = true
          pn = PredictionNeighborhood.new
          pn.prediction_model_id  = prediction_model_id
          pn.name                 = nb.name
          pn.regular_coefficient  = ImportFormatter.to_decimal row["regular"]
          pn.luxury_coefficient   = ImportFormatter.to_decimal row["luxurious"]
          pn.neighborhood_id      = nb.id
          pn.save!
        end

        binding.pry unless has_matching
      end


    end    
  end

end
