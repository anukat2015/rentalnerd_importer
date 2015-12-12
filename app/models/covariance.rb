class Covariance < ActiveRecord::Base

  RECOGNIZED_VARIANCE_FEATURES = [
    "level",
    "bedrooms",
    "bathrooms",
    "garage",
    "age",
    "elevation",
    "dist_to_park",
    "combination"
  ]

  NORMAL_VARIANCE_FEATURES = [
    "level",
    "bedrooms",
    "bathrooms",
    "garage",
    "age",
    "elevation",
    "dist_to_park"
  ]  

  class << self  

    def compute_intervals prediction_result
      exog_computation_1_t_sum = 0
      pm = prediction_result.prediction_model
      property = prediction_result.property

      RECOGNIZED_VARIANCE_FEATURES.each do |row_type|
        exog_computation_1_t_sum += self.compute_exog_sum_for_feature( pm.id, property, row_type )
      end
      pred_var = pm.mser + exog_computation_1_t_sum
      pred_std = Math.sqrt pred_var
      standard_error = 1.282

      payload = {
        pred_std: pred_std,
        interval_u: prediction_result.predicted_rent + standard_error * pred_std,
        interval_l: prediction_result.predicted_rent - standard_error * pred_std  
      }
    end

    def compute_exog_sum_for_feature prediction_model_id, property, row_type
      year = Time.now.year
      nb = property.neighborhoods.first
      if row_type == "combination"
        variances = self.matching_cols_for_combination_row prediction_model_id, nb.id, year, property.luxurious?
      else
        variances = self.matching_cols_for_normal_row prediction_model_id, row_type, nb.id, year, property.luxurious?
      end

      # Computes the matrix multiplication result for this particular feature
      matrix_multiplication_result = 0
      variances.each do |variance|
        case variance.col_type
        when "level"
          matrix_multiplication_result += variance.coefficient * property.level if property.level.present?
          
        when "bedrooms"
          matrix_multiplication_result += variance.coefficient * property.bedrooms if property.bedrooms.present?

        when "bathrooms"
          matrix_multiplication_result += variance.coefficient * property.bathrooms if property.bathrooms.present?

        when "garage"
          matrix_multiplication_result += variance.coefficient if property.garage.present?

        when "age"
          matrix_multiplication_result += variance.coefficient * ( Time.now.year - property.year_built ) if property.year_built.present?

        when "elevation"
          matrix_multiplication_result += variance.coefficient * property.elevation if property.elevation.present?

        when "dist_to_park"
          matrix_multiplication_result += variance.coefficient * property.dist_to_park if property.dist_to_park.present?

        when "combination"
          matrix_multiplication_result += variance.coefficient * property.sqft if property.sqft.present?
        end
      end

      # Performs Array multiplication of the corresponding attribute value with the 
      #   matrix_multiplecation result 
      case row_type
      when "level"
        return matrix_multiplication_result * property.level if property.level.present?
      when "bedrooms"
        return matrix_multiplication_result * property.bedrooms if property.bedrooms.present?
      when "bathrooms"
        return matrix_multiplication_result * property.bathrooms if property.bathrooms.present?
      when "garage"
        return matrix_multiplication_result if property.garage if property.garage.present?
      when "age"
        return matrix_multiplication_result * ( Time.now.year - property.year_built ) if property.year_built.present?
      when "elevation"
        return matrix_multiplication_result * property.elevation if property.elevation.present?
      when "dist_to_park"
        return matrix_multiplication_result * property.dist_to_park if property.dist_to_park.present?
      when "combination"
        return matrix_multiplication_result * property.sqft if property.sqft.present?
      end
      return 0  
    end

    def matching_cols_for_normal_row prediction_model_id, row_type, nid, year, is_luxurious
      year = Time.now.year      
      cv_norm = Covariance.where( 
        prediction_model_id: prediction_model_id,
        row_type: row_type,
        col_type: NORMAL_VARIANCE_FEATURES
      )

      cv_special = Covariance.where( 
        prediction_model_id: prediction_model_id,
        row_type: row_type,
        col_type: "combination",
        col_neighborhood_id: nid,
        col_year: year,
        col_is_luxurious: is_luxurious
      )
      
      cv_norm + cv_special
    end

    def matching_cols_for_combination_row prediction_model_id, nid, year, is_luxurious
      year = Time.now.year

      cv_norm = Covariance.where( 
        prediction_model_id: prediction_model_id,
        row_type: "combination",
        row_neighborhood_id: nid,
        row_year: year,
        row_is_luxurious: is_luxurious,
        col_type: NORMAL_VARIANCE_FEATURES
      )

      cv_special = Covariance.where( 
        prediction_model_id: prediction_model_id,
        row_type: "combination",
        row_neighborhood_id: nid,
        row_year: year,
        row_is_luxurious: is_luxurious,
        col_type: "combination",
        col_neighborhood_id: nid,
        col_year: year,
        col_is_luxurious: is_luxurious
      )     
      cv_norm + cv_special 

    end    

    def import_covariances! prediction_model_id, model_covariance_file
      CSV.new( open( model_covariance_file ), :headers => :first_row ).each do |record|

        row_key = record[0]
        puts "\t#{$.} importing covariance: #{row_key}"
        row_type = self.label_type row_key
        row_combi = self.breakdown_combination row_key        

        ActiveRecord::Base.transaction do
          record.each do |col_key, value|
            if col_key.present?
              col_type = self.label_type col_key
              col_combi = self.breakdown_combination col_key

              Covariance.create(
                prediction_model_id: prediction_model_id,
                row_type: row_type,
                row_neighborhood_id: row_combi["neighborhood_id"],
                row_year: row_combi["year"],
                row_is_luxurious: row_combi["is_luxurious"],
                col_type: col_type,
                col_neighborhood_id: col_combi["neighborhood_id"],
                col_year: col_combi["year"],
                col_is_luxurious: col_combi["is_luxurious"],
                row_raw: row_key,
                col_raw: col_key,
                coefficient: ImportFormatter.to_decimal(value)
              )
            end
          end          
        end

      end
    end

    def label_type covariance_label
      case covariance_label
      when "level", "bedrooms", "bathrooms", "garage", "age", "elevation", "dist_to_park"
        covariance_label
      when /^neighborhood/
        "combination"
      end        
    end

    # Given a covariance label, breaks it down into its various components
    #
    # Params:
    #   combination_string: String - E.g. 
    #       "neighborhood[Alamo Square]:sqft:year[Period('2011', 'A-DEC')]:luxurious[False]"
    #
    # Returns:
    #   breakdown:Hash
    #     neighborhood_id:Integer
    #     year:Integer  
    #     is_luxurious:Boolean  
    #
    def breakdown_combination combination_string
      breakdown = {}

      return breakdown unless combination_string =~ /^neighborhood.*/

      n_match = /neighborhood\[([^\].*]+)\]/.match combination_string
      n_string = n_match[1]
      nb = Neighborhood.where( name: n_string ).first
      breakdown["neighborhood_id"] = nb.id

      p_match = /Period\(\'([0-9]+)/.match combination_string
      breakdown["year"] = nil
      breakdown["year"] = p_match[1].to_i unless p_match.nil?

      l_match = /luxurious\[(.*)\]/.match combination_string
      breakdown["is_luxurious"] = l_match[1] == "True" unless l_match.nil?

      breakdown
    end
  end
end
